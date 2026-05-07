import os
from datetime import datetime
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from dotenv import load_dotenv

from real_ai_service import analyze_plant_image

load_dotenv()

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "status": "running",
        "message": "Krishi Sathi AI backend is running"
    })


@app.route("/uploads/<path:filename>", methods=["GET"])
def uploaded_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)


@app.route("/api/scan-plant", methods=["POST"])
def scan_plant():
    try:
        if "image" not in request.files:
            return jsonify({
                "success": False,
                "backendAiStatus": "failed",
                "backendAiMessage": "No image file received.",
                "backendAiMessageNe": "फोटो फाइल प्राप्त भएन।"
            }), 400

        image = request.files["image"]
        farmer_note = request.form.get("farmerNote", "")
        user_id = request.form.get("userId", "")

        if image.filename == "":
            return jsonify({
                "success": False,
                "backendAiStatus": "failed",
                "backendAiMessage": "Image filename is empty.",
                "backendAiMessageNe": "फोटो फाइलको नाम खाली छ।"
            }), 400

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        safe_filename = f"{timestamp}_{image.filename}"

        image_path = os.path.join(UPLOAD_FOLDER, safe_filename)
        image.save(image_path)

        host_url = request.host_url.rstrip("/")
        image_url = f"{host_url}/uploads/{safe_filename}"

        ai_result = analyze_plant_image(
            farmer_note=farmer_note,
            user_id=user_id,
            image_path=image_path,
            image_url=image_url,
        )

        return jsonify(ai_result), 200

    except Exception as e:
        return jsonify({
            "success": False,
            "backendAiStatus": "failed",
            "backendAiMessage": str(e),
            "backendAiMessageNe": "ब्याकएन्डमा समस्या भयो।"
        }), 500


@app.route("/api/market-ai-advice", methods=["POST"])
def market_ai_advice():
    try:
        data = request.get_json(silent=True) or {}

        crop_name = str(data.get("cropName", "Crop")).strip()
        crop_name_ne = str(data.get("cropNameNe", "बाली")).strip()
        price = str(data.get("price", "")).strip()
        unit = str(data.get("unit", "kg")).strip()
        market_name = str(data.get("marketName", "Local market")).strip()
        location = str(data.get("location", "")).strip()
        trend = str(data.get("trend", "Stable")).strip()
        note = str(data.get("note", "")).strip()

        if not crop_name:
            crop_name = "Crop"

        if not crop_name_ne:
            crop_name_ne = crop_name

        if not unit:
            unit = "kg"

        price_text = f"Rs. {price}/{unit}" if price else f"Rs. 0/{unit}"

        trend_lower = trend.lower()

        if "high" in trend_lower:
            risk = "Good selling opportunity"
            risk_ne = "बेच्न राम्रो अवसर"
            title = f"{crop_name} price looks good"
            title_ne = f"{crop_name_ne} को मूल्य राम्रो देखिन्छ"
            summary = (
                f"{crop_name} is showing strong demand in {market_name}. "
                f"The current price is around {price_text}. If your crop is ready, fresh, "
                f"and transport cost is low, selling now may be a good option."
            )
            summary_ne = (
                f"{market_name} मा {crop_name_ne} को माग राम्रो देखिन्छ। "
                f"हालको मूल्य करिब {price_text} छ। बाली तयार र ताजा छ भने अनि ढुवानी खर्च कम छ भने अहिले बेच्नु राम्रो हुन सक्छ।"
            )
            actions = [
                "Compare this price with one nearby market before selling.",
                "Check transport cost so profit does not reduce.",
                "Sell fresh and good quality crop first."
            ]
            actions_ne = [
                "बेच्नु अघि नजिकको अर्को बजारसँग मूल्य तुलना गर्नुहोस्।",
                "ढुवानी खर्च जाँच गर्नुहोस् ताकि नाफा कम नहोस्।",
                "पहिले ताजा र राम्रो गुणस्तरको बाली बेच्नुहोस्।"
            ]

        elif "low" in trend_lower:
            risk = "Low price warning"
            risk_ne = "कम मूल्य चेतावनी"
            title = f"{crop_name} price looks low"
            title_ne = f"{crop_name_ne} को मूल्य कम देखिन्छ"
            summary = (
                f"{crop_name} price in {market_name} looks low at about {price_text}. "
                f"If the crop can be stored safely, it may be better to compare other markets "
                f"or wait for a better price."
            )
            summary_ne = (
                f"{market_name} मा {crop_name_ne} को मूल्य करिब {price_text} भएर कम देखिन्छ। "
                f"बाली सुरक्षित रूपमा राख्न मिल्छ भने अरू बजारसँग तुलना गर्नु वा राम्रो मूल्य पर्खनु ठीक हुन सक्छ।"
            )
            actions = [
                "Do not rush to sell if the crop can be stored safely.",
                "Check another nearby market price.",
                "Sell only if crop quality may reduce soon."
            ]
            actions_ne = [
                "बाली सुरक्षित राख्न मिल्छ भने बेच्न हतार नगर्नुहोस्।",
                "नजिकको अर्को बजार मूल्य जाँच गर्नुहोस्।",
                "बालीको गुणस्तर छिट्टै घट्ने भए मात्र बेच्नुहोस्।"
            ]

        else:
            risk = "Stable price"
            risk_ne = "स्थिर मूल्य"
            title = f"{crop_name} price is stable"
            title_ne = f"{crop_name_ne} को मूल्य स्थिर छ"
            summary = (
                f"{crop_name} price in {market_name} is around {price_text} and looks stable. "
                f"Farmers should compare transport cost, crop freshness, and nearby market price before deciding."
            )
            summary_ne = (
                f"{market_name} मा {crop_name_ne} को मूल्य करिब {price_text} छ र स्थिर देखिन्छ। "
                f"बेच्नु अघि ढुवानी खर्च, बालीको ताजापन र नजिकको बजार मूल्य तुलना गर्नुहोस्।"
            )
            actions = [
                "Compare nearby market prices.",
                "Check transport and packaging cost.",
                "Sell when crop quality and price are both suitable."
            ]
            actions_ne = [
                "नजिकका बजार मूल्यहरू तुलना गर्नुहोस्।",
                "ढुवानी र प्याकिङ खर्च जाँच गर्नुहोस्।",
                "बालीको गुणस्तर र मूल्य दुवै ठीक हुँदा बेच्नुहोस्।"
            ]

        if note:
            summary = summary + f" Farmer note: {note}"
            summary_ne = summary_ne + f" किसान नोट: {note}"

        return jsonify({
            "success": True,
            "marketAiStatus": "completed",
            "marketAiMessage": "Market AI advice created successfully.",
            "marketAiMessageNe": "बजार एआई सुझाव सफलतापूर्वक तयार भयो।",
            "aiMarketTitle": title,
            "aiMarketTitleNe": title_ne,
            "aiMarketRisk": risk,
            "aiMarketRiskNe": risk_ne,
            "aiMarketSummary": summary,
            "aiMarketSummaryNe": summary_ne,
            "aiMarketActions": actions,
            "aiMarketActionsNe": actions_ne,
        }), 200

    except Exception as e:
        return jsonify({
            "success": False,
            "marketAiStatus": "failed",
            "marketAiMessage": str(e),
            "marketAiMessageNe": "बजार एआई सुझाव तयार गर्न समस्या भयो।",
            "aiMarketTitle": "Market advice unavailable",
            "aiMarketTitleNe": "बजार सुझाव उपलब्ध छैन",
            "aiMarketRisk": "Unknown",
            "aiMarketRiskNe": "थाहा छैन",
            "aiMarketSummary": "Could not create market advice right now.",
            "aiMarketSummaryNe": "अहिले बजार सुझाव बनाउन सकिएन।",
            "aiMarketActions": [],
            "aiMarketActionsNe": [],
        }), 500


if __name__ == "__main__":
    port = int(os.getenv("PORT", 5001))
    app.run(host="0.0.0.0", port=port, debug=True)