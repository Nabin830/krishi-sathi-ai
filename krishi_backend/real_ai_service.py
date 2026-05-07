import json
import os

from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()


def fallback_ai_result(
    farmer_note: str,
    user_id: str,
    image_path: str,
    image_url: str = "",
    reason: str = "Gemini AI is not connected yet.",
):
    return {
        "success": True,
        "backendAiStatus": "completed",
        "backendAiMessage": reason,
        "backendAiMessageNe": "Gemini एआई प्रयोग हुन सकेन। अस्थायी नतिजा प्रयोग गरियो।",

        "imageUrl": image_url,

        "aiStatus": "processed",

        "aiPlantName": "Not sure",
        "aiPlantNameNe": "निश्चित छैन",

        "aiAffectedPart": "Not sure",
        "aiAffectedPartNe": "निश्चित छैन",

        "aiProblemName": "AI fallback result",
        "aiProblemNameNe": "एआई fallback नतिजा",

        "aiProblemType": "Temporary result",
        "aiProblemTypeNe": "अस्थायी नतिजा",

        "aiConfidence": 40,

        "aiSeverity": "Unknown",
        "aiSeverityNe": "थाहा छैन",

        "aiUrgency": "Normal",
        "aiUrgencyNe": "सामान्य",

        "aiImageQuality": "Unknown",
        "aiImageQualityNe": "थाहा छैन",

        "aiWhatHappened": "The backend received the photo, but Gemini AI could not analyse it properly.",
        "aiWhatHappenedNe": "ब्याकएन्डले फोटो प्राप्त गर्‍यो, तर Gemini एआईले ठीकसँग विश्लेषण गर्न सकेन।",

        "aiWhyItHappened": "This can happen if the API key is missing, internet is unavailable, Gemini is busy, or the AI response is invalid.",
        "aiWhyItHappenedNe": "API key नभएको, इन्टरनेट समस्या भएको, Gemini व्यस्त भएको, वा AI response ठीक नभएको कारण यस्तो हुन सक्छ।",

        "aiTreatmentSteps": [
            "Use this as a temporary result only.",
            "Upload a clearer close photo of the affected plant part.",
            "Ask a local agriculture expert before using any chemical treatment."
        ],
        "aiTreatmentStepsNe": [
            "यसलाई अस्थायी नतिजा मात्र मान्नुहोस्।",
            "समस्या भएको बिरुवाको भागको अझ सफा नजिकको फोटो अपलोड गर्नुहोस्।",
            "कुनै रासायनिक उपचार प्रयोग गर्नु अघि स्थानीय कृषि विशेषज्ञसँग सल्लाह लिनुहोस्।"
        ],

        "aiPreventionTips": [
            "Use good lighting when taking the plant photo.",
            "Focus on the affected leaf, fruit, stem, flower, or root.",
            "Keep monitoring the crop for spreading symptoms."
        ],
        "aiPreventionTipsNe": [
            "बिरुवाको फोटो खिच्दा राम्रो उज्यालो प्रयोग गर्नुहोस्।",
            "समस्या भएको पात, फल, डाँठ, फूल वा जरामा फोकस गर्नुहोस्।",
            "लक्षण फैलिएको छ कि छैन नियमित जाँच गर्नुहोस्।"
        ],

        "aiWhenToAskExpert": "Ask an expert if the problem spreads quickly, many plants are affected, or the crop starts dying.",
        "aiWhenToAskExpertNe": "समस्या छिटो फैलियो, धेरै बिरुवा प्रभावित भए, वा बाली मर्न थाल्यो भने विशेषज्ञसँग सल्लाह लिनुहोस्।",

        "farmerNoteReceived": farmer_note,
        "userIdReceived": user_id,
        "savedImagePath": image_path,
        "fallbackReason": reason,
    }


def _clean_json_text(text: str) -> str:
    cleaned = text.strip()

    if cleaned.startswith("```json"):
        cleaned = cleaned.replace("```json", "", 1).strip()

    if cleaned.startswith("```"):
        cleaned = cleaned.replace("```", "", 1).strip()

    if cleaned.endswith("```"):
        cleaned = cleaned[:-3].strip()

    return cleaned


def _safe_list(value):
    if isinstance(value, list):
        return [str(item) for item in value if str(item).strip()]

    if isinstance(value, str) and value.strip():
        return [value.strip()]

    return []


def _safe_confidence(value):
    try:
        number = int(value)

        if number < 0:
            return 0

        if number > 100:
            return 100

        return number
    except Exception:
        return 50


def _normalise_ai_result(
    raw: dict,
    farmer_note: str,
    user_id: str,
    image_path: str,
    image_url: str = "",
):
    treatment_steps = _safe_list(raw.get("aiTreatmentSteps"))
    treatment_steps_ne = _safe_list(raw.get("aiTreatmentStepsNe"))
    prevention_tips = _safe_list(raw.get("aiPreventionTips"))
    prevention_tips_ne = _safe_list(raw.get("aiPreventionTipsNe"))

    if not treatment_steps:
        treatment_steps = [
            "Upload a clearer photo or ask a local agriculture expert for confirmation."
        ]

    if not treatment_steps_ne:
        treatment_steps_ne = [
            "अझ सफा फोटो अपलोड गर्नुहोस् वा पुष्टि गर्न स्थानीय कृषि विशेषज्ञसँग सल्लाह लिनुहोस्।"
        ]

    if not prevention_tips:
        prevention_tips = [
            "Monitor the plant regularly and keep the growing area clean."
        ]

    if not prevention_tips_ne:
        prevention_tips_ne = [
            "बिरुवा नियमित जाँच गर्नुहोस् र खेती गर्ने ठाउँ सफा राख्नुहोस्।"
        ]

    return {
        "success": True,
        "backendAiStatus": "completed",
        "backendAiMessage": "The plant  image analysed  successfully.",
        "backendAiMessageNe": "बिरुवाको फोटो सफलतापूर्वक विश्लेषण गर्‍यो।",

        "imageUrl": image_url,

        "aiStatus": "processed",

        "aiPlantName": str(raw.get("aiPlantName", "Not sure")),
        "aiPlantNameNe": str(raw.get("aiPlantNameNe", "निश्चित छैन")),

        "aiAffectedPart": str(raw.get("aiAffectedPart", "Not sure")),
        "aiAffectedPartNe": str(raw.get("aiAffectedPartNe", "निश्चित छैन")),

        "aiProblemName": str(raw.get("aiProblemName", "Not sure")),
        "aiProblemNameNe": str(raw.get("aiProblemNameNe", "निश्चित छैन")),

        "aiProblemType": str(raw.get("aiProblemType", "Possible plant problem")),
        "aiProblemTypeNe": str(raw.get("aiProblemTypeNe", "सम्भावित बिरुवा समस्या")),

        "aiConfidence": _safe_confidence(raw.get("aiConfidence", 50)),

        "aiSeverity": str(raw.get("aiSeverity", "Unknown")),
        "aiSeverityNe": str(raw.get("aiSeverityNe", "थाहा छैन")),

        "aiUrgency": str(raw.get("aiUrgency", "Normal")),
        "aiUrgencyNe": str(raw.get("aiUrgencyNe", "सामान्य")),

        "aiImageQuality": str(raw.get("aiImageQuality", "Unknown")),
        "aiImageQualityNe": str(raw.get("aiImageQualityNe", "थाहा छैन")),

        "aiWhatHappened": str(raw.get("aiWhatHappened", "")),
        "aiWhatHappenedNe": str(raw.get("aiWhatHappenedNe", "")),

        "aiWhyItHappened": str(raw.get("aiWhyItHappened", "")),
        "aiWhyItHappenedNe": str(raw.get("aiWhyItHappenedNe", "")),

        "aiTreatmentSteps": treatment_steps,
        "aiTreatmentStepsNe": treatment_steps_ne,

        "aiPreventionTips": prevention_tips,
        "aiPreventionTipsNe": prevention_tips_ne,

        "aiWhenToAskExpert": str(
            raw.get(
                "aiWhenToAskExpert",
                "Ask a local agriculture expert if the problem spreads, becomes severe, or you are unsure about treatment.",
            )
        ),
        "aiWhenToAskExpertNe": str(
            raw.get(
                "aiWhenToAskExpertNe",
                "समस्या फैलियो, गम्भीर भयो, वा उपचारबारे निश्चित नभए स्थानीय कृषि विशेषज्ञसँग सल्लाह लिनुहोस्।",
            )
        ),

        "farmerNoteReceived": farmer_note,
        "userIdReceived": user_id,
        "savedImagePath": image_path,
    }


def analyze_plant_image(
    farmer_note: str,
    user_id: str,
    image_path: str,
    image_url: str = "",
):
    api_key = os.getenv("GEMINI_API_KEY", "").strip()

    if not api_key or api_key == "PASTE_YOUR_GEMINI_API_KEY_HERE":
        return fallback_ai_result(
            farmer_note=farmer_note,
            user_id=user_id,
            image_path=image_path,
            image_url=image_url,
            reason="Gemini API key is missing.",
        )

    try:
        client = genai.Client(api_key=api_key)

        with open(image_path, "rb") as image_file:
            image_bytes = image_file.read()

        prompt = f"""
You are Krishi Sathi AI, a careful agriculture image assistant for farmers in Nepal.

Your task:
Analyse the uploaded image and farmer note, then return a safe, farmer-friendly plant/crop result in BOTH English and Nepali.

Farmer note:
{farmer_note}

STRICT OUTPUT RULES:
1. Return ONLY valid JSON.
2. Do not use markdown.
3. Do not add any text before or after JSON.
4. Do not wrap JSON in backticks.
5. Use exactly the required JSON keys.
6. All fields must be filled.
7. Use simple words that farmers can understand.
8. Nepali text must be natural Nepali, not broken direct translation.
9. Do not invent details that are not visible.
10. If unsure, say "Not sure" or "Possible", not a confident disease name.
11. Never recommend strong chemical or pesticide use directly.
12. Always advise asking a local agriculture expert before chemical spray.
13. aiConfidence must be an integer from 0 to 100.

STEP 1: IMAGE VALIDATION
First decide if the image is suitable for plant/crop diagnosis.

A valid image must clearly show at least one:
plant, crop, leaf, fruit, flower, stem, root, seedling, tree, vegetable plant, crop field, farming-related plant material.

If the image does NOT clearly show plant/crop material, return this meaning:
- aiPlantName: "Not a plant image"
- aiPlantNameNe: "बिरुवाको फोटो होइन"
- aiAffectedPart: "Not applicable"
- aiAffectedPartNe: "लागू हुँदैन"
- aiProblemName: "Invalid plant photo"
- aiProblemNameNe: "गलत बिरुवा फोटो"
- aiProblemType: "Invalid image"
- aiProblemTypeNe: "गलत फोटो"
- aiConfidence: 0
- aiSeverity: "Unknown"
- aiSeverityNe: "थाहा छैन"
- aiUrgency: "Invalid photo"
- aiUrgencyNe: "गलत फोटो"
- aiImageQuality: "Invalid"
- aiImageQualityNe: "गलत फोटो"
- aiWhatHappened: "This image does not look like a plant or crop photo."
- aiWhatHappenedNe: "यो फोटो बिरुवा वा बालीको फोटो जस्तो देखिँदैन।"
- aiWhyItHappened: "The uploaded image may not contain a clear plant, leaf, crop, fruit, flower, stem, or root."
- aiWhyItHappenedNe: "अपलोड गरिएको फोटोमा स्पष्ट बिरुवा, पात, बाली, फल, फूल, डाँठ वा जरा नदेखिएको हुन सक्छ।"
- aiTreatmentSteps: ["Please upload a clear close photo of the affected plant or crop."]
- aiTreatmentStepsNe: ["कृपया समस्या भएको बिरुवा वा बालीको नजिकबाट खिचिएको सफा फोटो अपलोड गर्नुहोस्।"]
- aiPreventionTips: ["Use good lighting and focus on the affected plant part."]
- aiPreventionTipsNe: ["राम्रो उज्यालोमा समस्या भएको बिरुवाको भागमा फोकस गरेर फोटो खिच्नुहोस्।"]
- aiWhenToAskExpert: "Ask a local agriculture expert if you are unsure what photo to upload."
- aiWhenToAskExpertNe: "कस्तो फोटो अपलोड गर्ने भन्ने निश्चित नभए स्थानीय कृषि विशेषज्ञसँग सोध्नुहोस्।"

STEP 2: IMAGE QUALITY CHECK
If it is plant/crop material but the photo is too blurry, dark, far away, blocked, or not clear enough:
- Do not guess disease.
- aiProblemName: "Unclear plant photo"
- aiProblemNameNe: "अस्पष्ट बिरुवा फोटो"
- aiProblemType: "Image quality issue"
- aiProblemTypeNe: "फोटो स्पष्ट नभएको समस्या"
- aiConfidence: 1 to 25
- aiSeverity: "Unknown"
- aiSeverityNe: "थाहा छैन"
- aiUrgency: "Upload clearer photo"
- aiUrgencyNe: "अझ सफा फोटो अपलोड गर्नुहोस्"
- aiImageQuality: "Poor"
- aiImageQualityNe: "कमजोर"
- Tell farmer to upload a clearer close-up photo of the affected part.

STEP 3: HEALTHY PLANT CHECK
If the plant looks healthy or normal:
- Do not invent disease.
- aiProblemName: "No clear disease detected"
- aiProblemNameNe: "स्पष्ट रोग देखिएन"
- aiProblemType: "Healthy or normal condition"
- aiProblemTypeNe: "स्वस्थ वा सामान्य अवस्था"
- aiSeverity: "None"
- aiSeverityNe: "समस्या देखिएन"
- aiUrgency: "Normal"
- aiUrgencyNe: "सामान्य"
- aiImageQuality: "Good" or "Medium"
- aiImageQualityNe: "राम्रो" or "मध्यम"
- aiConfidence: based on image clarity.
- Give normal care advice such as watering, sunlight, spacing, drainage, and monitoring.

STEP 4: DIAGNOSIS CHECK
If visible symptoms exist, classify the issue into one of these broad groups:
- Possible fungal disease
- Possible bacterial disease
- Possible viral disease
- Possible pest damage
- Possible nutrient deficiency
- Possible water stress
- Possible heat/sun stress
- Possible root problem
- Possible soil/drainage problem
- Physical damage
- Unknown plant stress
- Not sure

Use these visual clues carefully:
- Yellow leaves: possible nutrient deficiency, water stress, root issue, poor drainage, sunlight issue, or natural aging.
- Brown spots: possible fungal leaf spot, bacterial spot, pest damage, sunburn, or nutrient issue.
- White powder: possible powdery mildew, dust, residue, or unclear if not on leaf surface.
- Holes/chewed leaves: possible insect or pest damage, physical tearing, or animal damage.
- Wilting/drying: possible water stress, heat stress, root damage, disease, or transplant shock.
- Black/soft rot: possible rot or severe disease; advise expert quickly.
- Fruit spots/rot: possible fungal/bacterial rot, pest damage, or physical damage.
- Flower drop: possible heat stress, water stress, pollination issue, or nutrient imbalance.
- Stem/root issue: possible rot, pest, waterlogging, or mechanical damage.
- Many plants affected: possible spreading disease/pest or environmental issue.

DIAGNOSIS SAFETY:
- Identify only the most likely issue.
- Use "Possible" when not fully certain.
- Do not give a lab-level diagnosis from image alone.
- Do not recommend exact chemical products.
- Do not suggest unsafe or excessive treatment.
- Always include expert advice before chemical treatment.

TREATMENT ADVICE RULES:
Treatment steps must be practical and safe:
- First step should usually be observation/checking affected part.
- Include removal of badly affected leaves/fruits only when appropriate.
- Include watering/drainage/airflow/sunlight/spacing advice when relevant.
- Include "Ask a local agriculture expert before chemical spray" when disease or pest is suspected.
- Avoid naming strong chemicals.
- Do not promise cure.

PREVENTION ADVICE RULES:
Prevention tips should include relevant safe farming practices:
- good spacing
- clean field/garden
- avoid wetting leaves
- proper watering
- good drainage
- regular monitoring
- removing fallen infected leaves/fruits
- crop rotation where relevant
- healthy soil and balanced nutrients

SEVERITY, URGENCY, AND IMAGE QUALITY RULES:

aiSeverity must be one of:
- "None" if no problem is visible or plant looks healthy
- "Low" if symptoms are small, mild, or only a few leaves/fruits are affected
- "Medium" if symptoms are noticeable and may spread if ignored
- "High" if symptoms are severe, spreading, many parts are affected, rot is visible, or plant/crop may be seriously damaged
- "Unknown" if image is unclear or not enough information

aiSeverityNe must match:
- None = "समस्या देखिएन"
- Low = "कम"
- Medium = "मध्यम"
- High = "उच्च"
- Unknown = "थाहा छैन"

aiUrgency must be one of:
- "Normal" if farmer can monitor and continue normal care
- "Soon" if farmer should act within a few days
- "Urgent" if serious spreading, rot, wilting, many plants affected, or expert help is needed quickly
- "Upload clearer photo" if image is unclear
- "Invalid photo" if image is not a plant/crop image

aiUrgencyNe must match:
- Normal = "सामान्य"
- Soon = "चाँडै"
- Urgent = "जरुरी"
- Upload clearer photo = "अझ सफा फोटो अपलोड गर्नुहोस्"
- Invalid photo = "गलत फोटो"

aiImageQuality must be one of:
- "Good" if plant and symptom are clearly visible
- "Medium" if plant is visible but symptom is partly unclear
- "Poor" if photo is blurry, dark, far, blocked, or hard to diagnose
- "Invalid" if image is not a plant/crop image

aiImageQualityNe must match:
- Good = "राम्रो"
- Medium = "मध्यम"
- Poor = "कमजोर"
- Invalid = "गलत फोटो"

CONFIDENCE RULES:
- 0 = not a plant image
- 1 to 25 = plant image but unclear/low confidence
- 26 to 60 = possible issue but uncertain
- 61 to 85 = likely issue
- 86 to 100 = very clear visible issue
Do not use high confidence if the image is unclear or the symptom could have many causes.

FINAL JSON FORMAT:
Return only this JSON object with these exact keys:

{{
  "aiPlantName": "string",
  "aiPlantNameNe": "string",
  "aiAffectedPart": "string",
  "aiAffectedPartNe": "string",
  "aiProblemName": "string",
  "aiProblemNameNe": "string",
  "aiProblemType": "string",
  "aiProblemTypeNe": "string",
  "aiConfidence": 0,
  "aiSeverity": "string",
  "aiSeverityNe": "string",
  "aiUrgency": "string",
  "aiUrgencyNe": "string",
  "aiImageQuality": "string",
  "aiImageQualityNe": "string",
  "aiWhatHappened": "string",
  "aiWhatHappenedNe": "string",
  "aiWhyItHappened": "string",
  "aiWhyItHappenedNe": "string",
  "aiTreatmentSteps": ["string"],
  "aiTreatmentStepsNe": ["string"],
  "aiPreventionTips": ["string"],
  "aiPreventionTipsNe": ["string"],
  "aiWhenToAskExpert": "string",
  "aiWhenToAskExpertNe": "string"
}}
"""

        response = client.models.generate_content(
            model="gemini-2.5-flash-lite",
            contents=[
                types.Part.from_bytes(
                    data=image_bytes,
                    mime_type="image/jpeg",
                ),
                prompt,
            ],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
            ),
        )

        raw_text = response.text or ""
        cleaned = _clean_json_text(raw_text)
        decoded = json.loads(cleaned)

        if not isinstance(decoded, dict):
            return fallback_ai_result(
                farmer_note=farmer_note,
                user_id=user_id,
                image_path=image_path,
                image_url=image_url,
                reason="Gemini returned non-object JSON.",
            )

        return _normalise_ai_result(
            raw=decoded,
            farmer_note=farmer_note,
            user_id=user_id,
            image_path=image_path,
            image_url=image_url,
        )

    except Exception as e:
        return fallback_ai_result(
            farmer_note=farmer_note,
            user_id=user_id,
            image_path=image_path,
            image_url=image_url,
            reason=f"Gemini error: {str(e)}",
        )