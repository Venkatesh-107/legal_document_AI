import os
import json
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS
import fitz  # PyMuPDF
import pytesseract
from PIL import Image
from werkzeug.utils import secure_filename
from bs4 import BeautifulSoup
import google.generativeai as genai

# === Flask Setup ===
app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER

# === Gemini Setup ===
genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))

# === File Upload Route ===
@app.route("/upload", methods=["POST"])
def upload_file():
    if "file" not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "Empty filename"}), 400

    filename = secure_filename(file.filename)
    filepath = os.path.join(app.config["UPLOAD_FOLDER"], filename)
    file.save(filepath)

    extracted_text = ""
    try:
        # PDF
        if filename.lower().endswith(".pdf"):
            doc = fitz.open(filepath)
            for page in doc:
                extracted_text += page.get_text()
            doc.close()
        # Image
        elif filename.lower().endswith((".png", ".jpg", ".jpeg")):
            image = Image.open(filepath)
            extracted_text = pytesseract.image_to_string(image)
        # TXT
        elif filename.lower().endswith(".txt"):
            with open(filepath, "r", encoding="utf-8") as f:
                extracted_text = f.read()
        else:
            return jsonify({"error": "Unsupported file type"}), 400
    except Exception as e:
        return jsonify({"error": f"Extraction failed: {str(e)}"}), 500

    return jsonify({"extracted_text": extracted_text})


# === Summarize Route ===
@app.route("/summarize", methods=["POST"])
def summarize():
    try:
        data = request.get_json(force=True)
        text = data.get("text", "")
    except Exception as e:
        return jsonify({"error": f"Invalid JSON: {str(e)}"}), 400

    text = text.strip()
    if not text:
        return jsonify({
            "key_points": "No text extracted.",
            "risks": "N/A",
            "recommendations": "Please provide text, URL, or document."
        }), 200

    # Detect URL
    if text.startswith("http://") or text.startswith("https://"):
        try:
            resp = requests.get(text, timeout=10)
            resp.raise_for_status()
            soup = BeautifulSoup(resp.text, "html.parser")
            text = soup.get_text(separator="\n", strip=True)
            if len(text) < 50:
                return jsonify({
                    "key_points": "Fetched content too short for reliable summary.",
                    "risks": "⚠️ AI-generated summary. Verify manually.",
                    "recommendations": "Provide full document or longer webpage."
                }), 200
        except Exception as e:
            return jsonify({
                "key_points": "",
                "risks": "⚠️ Failed to fetch URL content",
                "recommendations": str(e)
            }), 200

    # AI Disclaimer for short text
    if len(text) < 50:
        return jsonify({
            "key_points": "Input too short. AI-generated summary may be unreliable.",
            "risks": "⚠️ Verify content manually.",
            "recommendations": "Paste full text, URL, or upload a document."
        }), 200

    # Gemini summarization
    try:
        prompt = f"""
        Summarize the following legal document into JSON with keys:
        key_points, risks, recommendations.

        Document Text:
        {text}
        """
        model = genai.GenerativeModel("gemini-1.5-flash")
        response = model.generate_content(prompt)

        try:
            parsed = json.loads(response.text)
            return jsonify(parsed)
        except Exception:
            return jsonify({
                "key_points": response.text,
                "risks": "",
                "recommendations": ""
            })
    except Exception as e:
        return jsonify({"error": f"Gemini API failed: {str(e)}"}), 500


if __name__ == "__main__":
    app.run(debug=True)
