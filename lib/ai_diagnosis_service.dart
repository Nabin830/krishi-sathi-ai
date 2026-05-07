class AiDiagnosisService {
  static Map<String, dynamic> diagnoseFromNote(String note) {
    final text = note.toLowerCase();

    if (text.contains('brown') ||
        text.contains('spot') ||
        text.contains('black')) {
      return {
        'backendAiStatus': 'basic_fallback',
        'backendAiMessage': 'Basic diagnosis created from farmer note.',
        'backendAiMessageNe': 'किसानको नोटबाट आधारभूत निदान बनाइयो।',

        'aiStatus': 'processed',
        'aiPlantName': 'Not sure',
        'aiPlantNameNe': 'निश्चित छैन',
        'aiAffectedPart': 'Leaf',
        'aiAffectedPartNe': 'पात',
        'aiProblemName': 'Possible fungal leaf spot',
        'aiProblemNameNe': 'सम्भावित फंगल पातको दाग',
        'aiProblemType': 'Possible disease',
        'aiProblemTypeNe': 'सम्भावित रोग',
        'aiConfidence': 55,

        'aiSeverity': 'Medium',
        'aiSeverityNe': 'मध्यम',
        'aiUrgency': 'Soon',
        'aiUrgencyNe': 'चाँडै',
        'aiImageQuality': 'Unknown',
        'aiImageQualityNe': 'थाहा छैन',

        'aiWhatHappened':
            'The plant may have leaf spots. This can happen when fungal infection spreads on leaves.',
        'aiWhatHappenedNe':
            'बिरुवाको पातमा दाग देखिएको हुन सक्छ। पातमा फंगल संक्रमण फैलिँदा यस्तो हुन सक्छ।',

        'aiWhyItHappened':
            'This often happens when leaves stay wet for long time or plants are too close together.',
        'aiWhyItHappenedNe':
            'पात लामो समय भिजिरहँदा वा बिरुवा धेरै नजिक रोपिँदा यस्तो समस्या देखिन सक्छ।',

        'aiTreatmentSteps': [
          'Remove badly affected leaves if possible.',
          'Avoid watering directly on the leaves.',
          'Keep the plant area clean and remove fallen infected leaves.',
          'Ask a local agriculture expert before using any chemical spray.',
        ],
        'aiTreatmentStepsNe': [
          'धेरै बिग्रिएका पातहरू सम्भव भए हटाउनुहोस्।',
          'सिधै पातमा पानी हाल्नबाट बच्नुहोस्।',
          'बिरुवा वरिपरि सफा राख्नुहोस् र झरेका संक्रमित पातहरू हटाउनुहोस्।',
          'कुनै रासायनिक औषधि प्रयोग गर्नु अघि स्थानीय कृषि विशेषज्ञसँग सल्लाह लिनुहोस्।',
        ],

        'aiPreventionTips': [
          'Keep enough space between plants for air flow.',
          'Water near the root instead of wetting the leaves.',
          'Check plants regularly for early spots.',
        ],
        'aiPreventionTipsNe': [
          'हावा राम्रो चल्न बिरुवाबीच पर्याप्त दूरी राख्नुहोस्।',
          'पात भिजाउने भन्दा जराको नजिक पानी दिनुहोस्।',
          'सुरुको दाग पहिचान गर्न नियमित रूपमा बिरुवा जाँच गर्नुहोस्।',
        ],

        'aiWhenToAskExpert':
            'Ask an expert if spots spread quickly or many plants are affected.',
        'aiWhenToAskExpertNe':
            'दाग छिटो फैलियो वा धेरै बिरुवा प्रभावित भए कृषि विशेषज्ञसँग सल्लाह लिनुहोस्।',

        'expertVerified': false,
      };
    }

    if (text.contains('yellow')) {
      return {
        'backendAiStatus': 'basic_fallback',
        'backendAiMessage': 'Basic diagnosis created from farmer note.',
        'backendAiMessageNe': 'किसानको नोटबाट आधारभूत निदान बनाइयो।',

        'aiStatus': 'processed',
        'aiPlantName': 'Not sure',
        'aiPlantNameNe': 'निश्चित छैन',
        'aiAffectedPart': 'Leaf',
        'aiAffectedPartNe': 'पात',
        'aiProblemName': 'Possible nutrient or water stress',
        'aiProblemNameNe': 'सम्भावित पोषण वा पानीको तनाव',
        'aiProblemType': 'Possible deficiency / stress',
        'aiProblemTypeNe': 'सम्भावित कमी / तनाव',
        'aiConfidence': 50,

        'aiSeverity': 'Low',
        'aiSeverityNe': 'कम',
        'aiUrgency': 'Normal',
        'aiUrgencyNe': 'सामान्य',
        'aiImageQuality': 'Unknown',
        'aiImageQualityNe': 'थाहा छैन',

        'aiWhatHappened':
            'The leaves are turning yellow. This may be due to nutrient deficiency, too much water, less water, or root stress.',
        'aiWhatHappenedNe':
            'पात पहेँलो हुँदैछ। यो पोषणको कमी, धेरै पानी, कम पानी वा जराको समस्याका कारण हुन सक्छ।',

        'aiWhyItHappened':
            'Yellow leaves can happen when the plant cannot take enough nutrients or when roots are damaged by water stress.',
        'aiWhyItHappenedNe':
            'बिरुवाले पर्याप्त पोषण लिन नसक्दा वा पानीको तनावले जरा कमजोर हुँदा पात पहेँलो हुन सक्छ।',

        'aiTreatmentSteps': [
          'Check if the soil is too dry or too wet.',
          'Do not overwater the plant.',
          'Use balanced fertilizer carefully if the crop needs nutrients.',
          'Check roots and lower leaves for more symptoms.',
        ],
        'aiTreatmentStepsNe': [
          'माटो धेरै सुख्खा छ कि धेरै भिजेको छ जाँच गर्नुहोस्।',
          'बिरुवामा धेरै पानी नहाल्नुहोस्।',
          'बालीलाई पोषण चाहिएको छ भने सन्तुलित मल सावधानीपूर्वक प्रयोग गर्नुहोस्।',
          'जरा र तलका पातहरूमा अन्य लक्षण छन् कि जाँच गर्नुहोस्।',
        ],

        'aiPreventionTips': [
          'Water regularly but avoid waterlogging.',
          'Use compost or proper fertilizer based on crop need.',
          'Keep farm drainage clear.',
        ],
        'aiPreventionTipsNe': [
          'नियमित पानी दिनुहोस् तर पानी जम्न नदिनुहोस्।',
          'बालीको आवश्यकता अनुसार कम्पोस्ट वा उचित मल प्रयोग गर्नुहोस्।',
          'खेतको पानी निकास सफा राख्नुहोस्।',
        ],

        'aiWhenToAskExpert':
            'Ask an expert if yellowing spreads to many plants or plant growth stops.',
        'aiWhenToAskExpertNe':
            'धेरै बिरुवामा पहेँलोपन फैलियो वा वृद्धि रोकियो भने विशेषज्ञसँग सल्लाह लिनुहोस्।',

        'expertVerified': false,
      };
    }

    if (text.contains('white') || text.contains('powder')) {
      return {
        'backendAiStatus': 'basic_fallback',
        'backendAiMessage': 'Basic diagnosis created from farmer note.',
        'backendAiMessageNe': 'किसानको नोटबाट आधारभूत निदान बनाइयो।',

        'aiStatus': 'processed',
        'aiPlantName': 'Not sure',
        'aiPlantNameNe': 'निश्चित छैन',
        'aiAffectedPart': 'Leaf',
        'aiAffectedPartNe': 'पात',
        'aiProblemName': 'Possible powdery mildew',
        'aiProblemNameNe': 'सम्भावित पाउडरी मिल्ड्यु',
        'aiProblemType': 'Possible fungal disease',
        'aiProblemTypeNe': 'सम्भावित फंगल रोग',
        'aiConfidence': 60,

        'aiSeverity': 'Medium',
        'aiSeverityNe': 'मध्यम',
        'aiUrgency': 'Soon',
        'aiUrgencyNe': 'चाँडै',
        'aiImageQuality': 'Unknown',
        'aiImageQualityNe': 'थाहा छैन',

        'aiWhatHappened':
            'White powder-like patches may indicate powdery mildew on leaves.',
        'aiWhatHappenedNe':
            'पातमा सेतो धुलोजस्तो देखिनु पाउडरी मिल्ड्युको संकेत हुन सक्छ।',

        'aiWhyItHappened':
            'This can happen in humid weather or when plants have poor airflow.',
        'aiWhyItHappenedNe':
            'आर्द्र मौसम वा बिरुवामा हावा राम्रो नचल्दा यस्तो समस्या देखिन सक्छ।',

        'aiTreatmentSteps': [
          'Remove heavily infected leaves.',
          'Improve airflow around the plant.',
          'Avoid overhead watering.',
          'Consult an agriculture expert for safe treatment options.',
        ],
        'aiTreatmentStepsNe': [
          'धेरै संक्रमित पातहरू हटाउनुहोस्।',
          'बिरुवा वरिपरि हावा चल्ने व्यवस्था मिलाउनुहोस्।',
          'माथिबाट पात भिज्ने गरी पानी हाल्नबाट बच्नुहोस्।',
          'सुरक्षित उपचारका लागि कृषि विशेषज्ञसँग सल्लाह लिनुहोस्।',
        ],

        'aiPreventionTips': [
          'Avoid planting too closely.',
          'Keep leaves dry when possible.',
          'Monitor early white patches regularly.',
        ],
        'aiPreventionTipsNe': [
          'बिरुवा धेरै नजिक नरोप्नुहोस्।',
          'सम्भव भए पात सुख्खा राख्नुहोस्।',
          'सुरुका सेतो दागहरू नियमित जाँच गर्नुहोस्।',
        ],

        'aiWhenToAskExpert':
            'Ask an expert if white patches spread fast or crop yield is affected.',
        'aiWhenToAskExpertNe':
            'सेतो दाग छिटो फैलियो वा उत्पादनमा असर पर्‍यो भने विशेषज्ञसँग सल्लाह लिनुहोस्।',

        'expertVerified': false,
      };
    }

    if (text.contains('insect') ||
        text.contains('bug') ||
        text.contains('hole') ||
        text.contains('pest')) {
      return {
        'backendAiStatus': 'basic_fallback',
        'backendAiMessage': 'Basic diagnosis created from farmer note.',
        'backendAiMessageNe': 'किसानको नोटबाट आधारभूत निदान बनाइयो।',

        'aiStatus': 'processed',
        'aiPlantName': 'Not sure',
        'aiPlantNameNe': 'निश्चित छैन',
        'aiAffectedPart': 'Leaf',
        'aiAffectedPartNe': 'पात',
        'aiProblemName': 'Possible pest damage',
        'aiProblemNameNe': 'सम्भावित किराको क्षति',
        'aiProblemType': 'Possible insect/pest issue',
        'aiProblemTypeNe': 'सम्भावित किरा समस्या',
        'aiConfidence': 58,

        'aiSeverity': 'Medium',
        'aiSeverityNe': 'मध्यम',
        'aiUrgency': 'Soon',
        'aiUrgencyNe': 'चाँडै',
        'aiImageQuality': 'Unknown',
        'aiImageQualityNe': 'थाहा छैन',

        'aiWhatHappened':
            'The plant may be damaged by insects or pests, especially if leaves have holes or insects are visible.',
        'aiWhatHappenedNe':
            'पातमा प्वाल देखिएको वा किरा देखिएको छ भने बिरुवामा किराले क्षति गरेको हुन सक्छ।',

        'aiWhyItHappened':
            'Pests can increase when crops are not monitored or when weather supports pest growth.',
        'aiWhyItHappenedNe':
            'बाली नियमित जाँच नगर्दा वा मौसम किराको वृद्धि अनुकूल हुँदा किरा बढ्न सक्छ।',

        'aiTreatmentSteps': [
          'Check underside of leaves for insects or eggs.',
          'Remove visible pests manually if possible.',
          'Use safe pest control methods recommended by local experts.',
          'Avoid unnecessary strong chemicals.',
        ],
        'aiTreatmentStepsNe': [
          'पातको तलपट्टि किरा वा अण्डा छन् कि जाँच गर्नुहोस्।',
          'देखिएका किरा सम्भव भए हातैले हटाउनुहोस्।',
          'स्थानीय विशेषज्ञले सिफारिस गरेका सुरक्षित किरा नियन्त्रण उपाय अपनाउनुहोस्।',
          'आवश्यक नभई कडा रसायन प्रयोग नगर्नुहोस्।',
        ],

        'aiPreventionTips': [
          'Check crops every few days.',
          'Keep the field clean.',
          'Use pest traps if suitable for the crop.',
        ],
        'aiPreventionTipsNe': [
          'केही दिनको फरकमा बाली जाँच गर्नुहोस्।',
          'खेत सफा राख्नुहोस्।',
          'बालीका लागि उपयुक्त भए किरा पासो प्रयोग गर्नुहोस्।',
        ],

        'aiWhenToAskExpert':
            'Ask an expert if many plants are affected or pests return after control.',
        'aiWhenToAskExpertNe':
            'धेरै बिरुवा प्रभावित भए वा नियन्त्रण पछि पनि किरा फर्किए विशेषज्ञसँग सल्लाह लिनुहोस्।',

        'expertVerified': false,
      };
    }

    if (text.contains('dry') ||
        text.contains('dying') ||
        text.contains('wilting')) {
      return {
        'backendAiStatus': 'basic_fallback',
        'backendAiMessage': 'Basic diagnosis created from farmer note.',
        'backendAiMessageNe': 'किसानको नोटबाट आधारभूत निदान बनाइयो।',

        'aiStatus': 'processed',
        'aiPlantName': 'Not sure',
        'aiPlantNameNe': 'निश्चित छैन',
        'aiAffectedPart': 'Whole plant',
        'aiAffectedPartNe': 'पूरा बिरुवा',
        'aiProblemName': 'Possible water stress or root problem',
        'aiProblemNameNe': 'सम्भावित पानी तनाव वा जराको समस्या',
        'aiProblemType': 'Possible stress',
        'aiProblemTypeNe': 'सम्भावित तनाव',
        'aiConfidence': 52,

        'aiSeverity': 'Medium',
        'aiSeverityNe': 'मध्यम',
        'aiUrgency': 'Soon',
        'aiUrgencyNe': 'चाँडै',
        'aiImageQuality': 'Unknown',
        'aiImageQualityNe': 'थाहा छैन',

        'aiWhatHappened':
            'The plant may be drying or wilting because of water stress, root damage, heat, or disease.',
        'aiWhatHappenedNe':
            'पानीको तनाव, जराको क्षति, गर्मी वा रोगका कारण बिरुवा सुक्ने वा ओइलाउने हुन सक्छ।',

        'aiWhyItHappened':
            'Wilting can happen when roots cannot supply enough water to the plant.',
        'aiWhyItHappenedNe':
            'जराले बिरुवालाई पर्याप्त पानी दिन नसक्दा बिरुवा ओइलाउन सक्छ।',

        'aiTreatmentSteps': [
          'Check soil moisture near the root.',
          'Check if roots are damaged or rotting.',
          'Water properly but avoid waterlogging.',
          'Give shade temporarily if heat is extreme.',
        ],
        'aiTreatmentStepsNe': [
          'जराको नजिक माटोको चिस्यान जाँच गर्नुहोस्।',
          'जरा बिग्रिएको वा कुहिएको छ कि जाँच गर्नुहोस्।',
          'ठिक मात्रामा पानी दिनुहोस् तर पानी जम्न नदिनुहोस्।',
          'धेरै गर्मी भए केही समयका लागि छायाँ दिनुहोस्।',
        ],

        'aiPreventionTips': [
          'Maintain regular irrigation.',
          'Improve soil drainage.',
          'Check plants during hot weather.',
        ],
        'aiPreventionTipsNe': [
          'नियमित सिँचाइ कायम राख्नुहोस्।',
          'माटोको पानी निकास सुधार गर्नुहोस्।',
          'गर्मी मौसममा बिरुवा नियमित जाँच गर्नुहोस्।',
        ],

        'aiWhenToAskExpert':
            'Ask an expert if plants continue dying even after proper watering.',
        'aiWhenToAskExpertNe':
            'ठिकसँग पानी दिँदा पनि बिरुवा मर्दै गयो भने विशेषज्ञसँग सल्लाह लिनुहोस्।',

        'expertVerified': false,
      };
    }

    return {
      'aiStatus': 'processed',
      'aiPlantName': 'Not sure',
      'aiPlantNameNe': 'निश्चित छैन',
      'aiAffectedPart': 'Plant',
      'aiAffectedPartNe': 'बिरुवा',
      'aiProblemName': 'Photo needs expert review',
      'aiProblemNameNe': 'फोटो विशेषज्ञले हेर्नुपर्ने',
      'aiProblemType': 'General plant check',
      'aiProblemTypeNe': 'सामान्य बिरुवा जाँच',
      'aiConfidence': 30,

      'aiSeverity': 'Unknown',
      'aiSeverityNe': 'थाहा छैन',

      'aiUrgency': 'Normal',
      'aiUrgencyNe': 'सामान्य',

      'aiImageQuality': 'Unknown',
      'aiImageQualityNe': 'थाहा छैन',

      'aiWhatHappened':
          'The app saved your plant report. The note does not give enough symptom detail, so this needs expert review or clearer symptom information.',
      'aiWhatHappenedNe':
          'एपले तपाईंको बिरुवा रिपोर्ट सेभ गरेको छ। नोटमा पर्याप्त लक्षण विवरण छैन, त्यसैले विशेषज्ञ समीक्षा वा थप स्पष्ट लक्षण चाहिन्छ।',

      'aiWhyItHappened':
          'Plant problems can happen because of disease, pests, water stress, nutrient deficiency, weather, or soil condition.',
      'aiWhyItHappenedNe':
          'बिरुवामा समस्या रोग, किरा, पानीको तनाव, पोषण कमी, मौसम वा माटोको अवस्थाका कारण हुन सक्छ।',

      'aiTreatmentSteps': [
        'Check leaves, stem, fruit and roots carefully.',
        'Add clear symptoms such as yellow leaves, brown spots, insects, holes, white powder, drying or wilting.',
        'Keep the plant area clean and avoid overwatering.',
        'Wait for expert/admin review before using chemical medicine.',
      ],
      'aiTreatmentStepsNe': [
        'पात, डाँठ, फल र जरा ध्यान दिएर जाँच गर्नुहोस्।',
        'पात पहेँलो, खैरो दाग, किरा, प्वाल, सेतो धुलो, सुक्ने वा ओइलाउने जस्ता स्पष्ट लक्षण थप्नुहोस्।',
        'बिरुवा वरिपरि सफा राख्नुहोस् र धेरै पानी नहाल्नुहोस्।',
        'रासायनिक औषधि प्रयोग गर्नु अघि विशेषज्ञ/एडमिन समीक्षाको प्रतीक्षा गर्नुहोस्।',
      ],

      'aiPreventionTips': [
        'Take clear close photos of the affected plant part.',
        'Check crops regularly for early signs.',
        'Keep proper spacing and drainage in the field.',
      ],
      'aiPreventionTipsNe': [
        'समस्या भएको भागको सफा नजिकको फोटो खिच्नुहोस्।',
        'सुरुको लक्षणका लागि बाली नियमित जाँच गर्नुहोस्।',
        'खेतमा उचित दूरी र पानी निकास कायम राख्नुहोस्।',
      ],

      'aiWhenToAskExpert':
          'Ask an expert if the problem spreads, plant starts dying, or you are not sure what medicine to use.',
      'aiWhenToAskExpertNe':
          'समस्या फैलियो, बिरुवा मर्न थाल्यो, वा कुन औषधि प्रयोग गर्ने थाहा भएन भने विशेषज्ञसँग सल्लाह लिनुहोस्।',

      'expertVerified': false,
    };
  }
}
