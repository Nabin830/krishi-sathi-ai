import json
import os

from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()


def fallback_weather_summary(
    crop_name: str,
    crop_name_ne: str,
    place_name: str,
    temperature: str,
    humidity: str,
    rain_chance: str,
    wind_speed: str,
    reason: str = "Gemini AI is not connected yet.",
):
    return {
        "success": True,
        "weatherAiStatus": "fallback",
        "weatherAiMessage": reason,
        "weatherAiMessageNe": "Gemini एआई प्रयोग हुन सकेन। सामान्य मौसम सुझाव प्रयोग गरियो।",

        "aiWeatherTitle": "Basic Weather Advice",
        "aiWeatherTitleNe": "सामान्य मौसम सुझाव",

        "aiWeatherSummary": (
            f"For {crop_name} in {place_name}, the current weather is "
            f"{temperature} with {humidity} humidity, {rain_chance} rain chance, "
            f"and {wind_speed} wind. Follow normal crop care and monitor the crop."
        ),
        "aiWeatherSummaryNe": (
            f"{place_name} मा {crop_name_ne} का लागि हालको मौसम {temperature}, "
            f"आर्द्रता {humidity}, पानी पर्ने सम्भावना {rain_chance}, "
            f"र हावा {wind_speed} छ। सामान्य बाली हेरचाह गर्नुहोस् र नियमित जाँच गर्नुहोस्।"
        ),

        "aiWeatherRisk": "Normal",
        "aiWeatherRiskNe": "सामान्य",

        "aiWeatherActions": [
            "Check soil moisture before watering.",
            "Avoid spraying if rain or strong wind is expected.",
            "Monitor leaves and crop growth regularly."
        ],
        "aiWeatherActionsNe": [
            "पानी दिनु अघि माटोको चिस्यान जाँच गर्नुहोस्।",
            "पानी वा धेरै हावा हुने सम्भावना भए छर्कने काम नगर्नुहोस्।",
            "पात र बालीको वृद्धि नियमित जाँच गर्नुहोस्।"
        ],

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
        return [str(item).strip() for item in value if str(item).strip()]

    if isinstance(value, str) and value.strip():
        return [value.strip()]

    return []


def _normalise_weather_ai_result(raw: dict):
    actions = _safe_list(raw.get("aiWeatherActions"))
    actions_ne = _safe_list(raw.get("aiWeatherActionsNe"))

    if not actions:
        actions = [
            "Check soil moisture before watering.",
            "Avoid spraying if rain or strong wind is expected.",
            "Monitor crop health regularly."
        ]

    if not actions_ne:
        actions_ne = [
            "पानी दिनु अघि माटोको चिस्यान जाँच गर्नुहोस्।",
            "पानी वा धेरै हावा हुने सम्भावना भए छर्कने काम नगर्नुहोस्।",
            "बालीको स्वास्थ्य नियमित जाँच गर्नुहोस्।"
        ]

    return {
        "success": True,
        "weatherAiStatus": "completed",
        "weatherAiMessage": "Gemini AI created weather farming advice successfully.",
        "weatherAiMessageNe": "Gemini एआईले मौसम खेती सुझाव सफलतापूर्वक तयार गर्‍यो।",

        "aiWeatherTitle": str(raw.get("aiWeatherTitle", "AI Weather Advice")),
        "aiWeatherTitleNe": str(raw.get("aiWeatherTitleNe", "एआई मौसम सुझाव")),

        "aiWeatherSummary": str(raw.get("aiWeatherSummary", "")),
        "aiWeatherSummaryNe": str(raw.get("aiWeatherSummaryNe", "")),

        "aiWeatherRisk": str(raw.get("aiWeatherRisk", "Normal")),
        "aiWeatherRiskNe": str(raw.get("aiWeatherRiskNe", "सामान्य")),

        "aiWeatherActions": actions,
        "aiWeatherActionsNe": actions_ne,
    }


def generate_weather_ai_summary(data: dict):
    api_key = os.getenv("GEMINI_API_KEY", "").strip()

    crop_name = str(data.get("cropName", "Crop"))
    crop_name_ne = str(data.get("cropNameNe", "बाली"))
    place_name = str(data.get("placeName", "Selected place"))
    temperature = str(data.get("temperature", ""))
    humidity = str(data.get("humidity", ""))
    rain_chance = str(data.get("rainChance", ""))
    wind_speed = str(data.get("windSpeed", ""))
    weather_type = str(data.get("weatherType", ""))
    main_alert = str(data.get("mainAlert", ""))
    local_advice = str(data.get("localAdvice", ""))
    forecast_text = str(data.get("forecastText", ""))

    if not api_key or api_key == "PASTE_YOUR_GEMINI_API_KEY_HERE":
        return fallback_weather_summary(
            crop_name=crop_name,
            crop_name_ne=crop_name_ne,
            place_name=place_name,
            temperature=temperature,
            humidity=humidity,
            rain_chance=rain_chance,
            wind_speed=wind_speed,
            reason="Gemini API key is missing.",
        )

    try:
        client = genai.Client(api_key=api_key)

        prompt = f"""
You are Krishi Sathi AI, a simple farming weather advisor for farmers in Nepal.

Create a short, clear weather farming summary in BOTH English and Nepali.

Farmer crop:
{crop_name}

Crop Nepali:
{crop_name_ne}

Place:
{place_name}

Current weather:
- Weather type: {weather_type}
- Temperature: {temperature}
- Humidity: {humidity}
- Rain chance: {rain_chance}
- Wind speed: {wind_speed}

Local app alert:
{main_alert}

Local app crop advice:
{local_advice}

5-day forecast summary:
{forecast_text}

STRICT OUTPUT RULES:
1. Return ONLY valid JSON.
2. Do not use markdown.
3. Do not add any text before or after JSON.
4. Keep the advice simple for farmers.
5. Do not give complicated scientific explanation.
6. Do not recommend strong chemicals.
7. If spraying is mentioned, say avoid spraying in rain or wind and ask an expert before chemical use.
8. Give only 3 farmer actions.
9. Nepali must be natural and easy to understand.

Return exactly this JSON:

{{
  "aiWeatherTitle": "string",
  "aiWeatherTitleNe": "string",
  "aiWeatherSummary": "string",
  "aiWeatherSummaryNe": "string",
  "aiWeatherRisk": "Normal/Rain Risk/Heat Risk/Cold Risk/Wind Risk/Disease Risk",
  "aiWeatherRiskNe": "सामान्य/पानी जोखिम/गर्मी जोखिम/चिसो जोखिम/हावा जोखिम/रोग जोखिम",
  "aiWeatherActions": ["string", "string", "string"],
  "aiWeatherActionsNe": ["string", "string", "string"]
}}
"""

        response = client.models.generate_content(
            model="gemini-2.5-flash-lite",
            contents=[prompt],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
            ),
        )

        raw_text = response.text or ""
        cleaned = _clean_json_text(raw_text)
        decoded = json.loads(cleaned)

        if not isinstance(decoded, dict):
            return fallback_weather_summary(
                crop_name=crop_name,
                crop_name_ne=crop_name_ne,
                place_name=place_name,
                temperature=temperature,
                humidity=humidity,
                rain_chance=rain_chance,
                wind_speed=wind_speed,
                reason="Gemini returned non-object JSON.",
            )

        return _normalise_weather_ai_result(decoded)

    except Exception as e:
        return fallback_weather_summary(
            crop_name=crop_name,
            crop_name_ne=crop_name_ne,
            place_name=place_name,
            temperature=temperature,
            humidity=humidity,
            rain_chance=rain_chance,
            wind_speed=wind_speed,
            reason=f"Gemini error: {str(e)}",
        )