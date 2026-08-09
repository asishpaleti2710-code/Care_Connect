from typing import Dict, Any, List
import re

class AIAgentService:
    """
    CarePulse AI — Comprehensive Medical, Pharmacology & CareConnect Platform Knowledge Engine.
    Provides medical triage, detailed drug/medicine information, emergency protocols, and app navigation assistance.
    """

    def __init__(self):
        # Comprehensive Medicine Database
        self.medicines_db = {
            "paracetamol": {
                "name": "Paracetamol / Acetaminophen",
                "category": "Analgesic & Antipyretic (Pain & Fever)",
                "dosage": "500mg - 1000mg every 4-6 hours (Max 4000mg/day).",
                "indications": "Mild to moderate pain, fever reduction.",
                "warnings": "Avoid excessive doses to prevent hepatic (liver) toxicity. Avoid combining with alcohol or other acetaminophen products.",
            },
            "acetaminophen": {
                "name": "Paracetamol / Acetaminophen",
                "category": "Analgesic & Antipyretic",
                "dosage": "500mg - 1000mg every 4-6 hours (Max 4g/day).",
                "indications": "Fever, mild aches and pains.",
                "warnings": "Watch max daily limit to protect liver.",
            },
            "ibuprofen": {
                "name": "Ibuprofen (Advil / Motrin)",
                "category": "NSAID (Non-Steroidal Anti-Inflammatory Drug)",
                "dosage": "200mg - 400mg every 6-8 hours with food (Max 1200mg/day OTC).",
                "indications": "Inflammation, joint pain, muscle pain, dental pain, fever.",
                "warnings": "Take with food or milk to prevent gastric ulceration. Caution in seniors with renal impairment or hypertension.",
            },
            "aspirin": {
                "name": "Aspirin (Acetylsalicylic Acid)",
                "category": "Antiplatelet / NSAID",
                "dosage": "81mg daily (low-dose heart protection) or 325mg for acute chest pain.",
                "indications": "Cardiovascular risk reduction, blood clot prevention.",
                "warnings": "Chew 325mg immediately during suspected cardiac emergency if not allergic. Watch for gastrointestinal bleeding.",
            },
            "amlodipine": {
                "name": "Amlodipine (Norvasc)",
                "category": "Calcium Channel Blocker (Antihypertensive)",
                "dosage": "5mg - 10mg once daily.",
                "indications": "Hypertension (high blood pressure) and coronary artery disease.",
                "warnings": "May cause peripheral edema (swollen ankles) and dizziness. Monitor blood pressure regularly.",
            },
            "lisinopril": {
                "name": "Lisinopril (Zestril / Prinivil)",
                "category": "ACE Inhibitor",
                "dosage": "10mg - 40mg once daily.",
                "indications": "Hypertension, heart failure, post-myocardial infarction.",
                "warnings": "Watch for persistent dry cough, hyperkalemia, or angioedema. Check renal function.",
            },
            "metoprolol": {
                "name": "Metoprolol (Lopressor / Toprol-XL)",
                "category": "Beta-Blocker",
                "dosage": "25mg - 100mg once or twice daily.",
                "indications": "Angina, hypertension, arrhythmia, heart failure.",
                "warnings": "Do not stop abruptly. Monitor heart rate (do not administer if pulse <50 bpm).",
            },
            "atorvastatin": {
                "name": "Atorvastatin (Lipitor)",
                "category": "Statin (HMG-CoA Reductase Inhibitor)",
                "dosage": "10mg - 80mg once daily at evening/bedtime.",
                "indications": "Hyperlipidemia (high cholesterol) & stroke prevention.",
                "warnings": "Report unexplained muscle pain, tenderness, or weakness (rhabdomyolysis risk).",
            },
            "metformin": {
                "name": "Metformin (Glucophage)",
                "category": "Biguanide Antidiabetic",
                "dosage": "500mg - 1000mg twice daily with meals.",
                "indications": "Type 2 Diabetes Mellitus blood glucose control.",
                "warnings": "Take with meals to minimize GI distress. Temporarily hold prior to IV contrast iodine dye procedures.",
            },
            "insulin": {
                "name": "Insulin (Rapid / Intermediate / Long-Acting)",
                "category": "Hormone / Antidiabetic",
                "dosage": "Individualized subcutaneous injection per sliding scale.",
                "indications": "Diabetes mellitus blood sugar management.",
                "warnings": "High risk of hypoglycemia! Keep fast-acting glucose (15g sugar / orange juice) immediately accessible.",
            },
            "albuterol": {
                "name": "Albuterol / Salbutamol Inhaler (Ventolin / ProAir)",
                "category": "Short-Acting Beta-2 Agonist (Bronchodilator)",
                "dosage": "1-2 puffs every 4-6 hours as needed for bronchospasm.",
                "indications": "Acute asthma attacks, wheezing, COPD respiratory distress.",
                "warnings": "May cause temporary tachycardia (racing heart) and tremors.",
            },
            "omeprazole": {
                "name": "Omeprazole (Prilosec)",
                "category": "Proton Pump Inhibitor (PPI)",
                "dosage": "20mg - 40mg once daily 30 minutes before morning breakfast.",
                "indications": "GERD, acid reflux, gastric ulcers.",
                "warnings": "Long-term use requires monitoring magnesium and vitamin B12 levels.",
            },
            "donepezil": {
                "name": "Donepezil (Aricept)",
                "category": "Cholinesterase Inhibitor",
                "dosage": "5mg - 10mg once daily at bedtime.",
                "indications": "Mild to severe Alzheimer's disease & dementia cognitive support.",
                "warnings": "May cause bradycardia (slow heart rate), nausea, and vivid dreams.",
            },
            "warfarin": {
                "name": "Warfarin (Coumadin) / Apixaban (Eliquis)",
                "category": "Anticoagulant (Blood Thinner)",
                "dosage": "Dosed per INR blood testing target (typically INR 2.0 - 3.0).",
                "indications": "Atrial fibrillation, DVT, PE clot prevention.",
                "warnings": "High bleeding risk! Report dark tarry stools, unusual bruising, or prolonged bleeding immediately.",
            },
            "nitroglycerin": {
                "name": "Nitroglycerin (Sublingual Tablets / Spray)",
                "category": "Vasodilator",
                "dosage": "1 tablet (0.4mg) under tongue every 5 mins up to 3 doses during acute angina.",
                "indications": "Acute chest pain / Angina pectoris.",
                "warnings": "If chest pain persists after 1st dose, call 911 / press CareConnect SOS immediately. Do NOT combine with PDE5 inhibitors (Viagra/Cialis).",
            }
        }

    def classify_emergency(self, description: str) -> Dict[str, Any]:
        text = description.lower() if description else ""

        if any(kw in text for kw in ["break in", "intruder", "thief", "gun", "knife", "threat", "attack"]):
            category = "Security Threat"
            priority = "Critical"
            suggested_responders = ["Security Responders", "Guardians", "Admin Command Center"]
            advice = "Lock all doors immediately, stay hidden, and stay low. On-duty security has been dispatched to your location coordinates."
        elif any(kw in text for kw in ["fell", "fall", "slipped", "trip", "collapsed", "unconscious"]):
            category = "Fall Incident"
            priority = "High"
            suggested_responders = ["Volunteer Responders", "Campus Security", "Family Guardians"]
            advice = "Do not move the resident if head or spinal injury is suspected. Keep the resident warm with a blanket and check breathing."
        elif any(kw in text for kw in ["chest pain", "heart", "stroke", "bleeding", "seizure", "breathing", "breath"]):
            category = "Medical Emergency"
            priority = "Critical"
            suggested_responders = ["Medical Volunteers", "Family Guardians", "Emergency Responders"]
            advice = "Sit upright, loosen tight clothing around neck/chest, and try to maintain calm deep breaths. Emergency medical team has been alerted."
        elif any(kw in text for kw in ["fire", "smoke", "gas", "leak"]):
            category = "Fire & Hazard"
            priority = "Critical"
            suggested_responders = ["Security Responders", "Facility Manager"]
            advice = "Evacuate the room immediately via safety exits. Do NOT use elevators."
        else:
            category = "General SOS Alert"
            priority = "High"
            suggested_responders = ["Volunteers", "Campus Security", "Guardians"]
            advice = "Emergency dispatch signal broadcast to active network responders."

        return {
            "description": description,
            "category": category,
            "priority": priority,
            "suggested_responders": suggested_responders,
            "immediate_advice": advice
        }

    def analyze_medical_notes(self, full_name: str, age: int, medical_notes: str) -> Dict[str, Any]:
        notes_lower = medical_notes.lower() if medical_notes else ""
        matched_high = [kw for kw in ["fall", "pacemaker", "cardiac", "stroke", "seizure", "bleeding"] if kw in notes_lower]
        matched_mod = [kw for kw in ["hypertension", "diabetes", "arthritis", "dementia", "dizziness"] if kw in notes_lower]

        if matched_high or age >= 85:
            risk_level = "High"
            risk_score = 85
            summary = f"High priority clinical monitoring required for {full_name} ({age} yrs). Critical risk factors identified: {', '.join(matched_high) if matched_high else 'Advanced age risk'}."
            recommendations = [
                "Verify resident has CareConnect wearable/SOS button within immediate reach.",
                "Perform vitals check (BP, SpO2, Heart Rate) twice daily.",
                "Ensure night sensor telemetry is active for fall detection."
            ]
        elif matched_mod or age >= 75:
            risk_level = "Moderate"
            risk_score = 55
            summary = f"Moderate wellness monitoring for {full_name} ({age} yrs). Active conditions: {', '.join(matched_mod) if matched_mod else 'Standard senior care'}."
            recommendations = [
                "Daily blood pressure and medication adherence logging.",
                "Ensure hydration and light mobility exercises."
            ]
        else:
            risk_level = "Low"
            risk_score = 20
            summary = f"Standard wellness routine active for {full_name}."
            recommendations = ["Standard weekly wellness check-in."]

        return {
            "resident_name": full_name,
            "risk_level": risk_level,
            "risk_score": risk_score,
            "summary": summary,
            "recommendations": recommendations
        }

    def answer_caregiver_query(self, query: str, context: Dict[str, Any] = None) -> str:
        q_lower = query.lower().strip() if query else ""

        # 1. Search Medicine Database
        for med_key, info in self.medicines_db.items():
            if med_key in q_lower:
                return (
                    f"💊 **{info['name']} ({info['category']})**\n\n"
                    f"• **Dosage**: {info['dosage']}\n"
                    f"• **Indications**: {info['indications']}\n"
                    f"• **Important Clinical Warnings**: {info['warnings']}\n\n"
                    f"*Always verify medication administration against 5 Rights: Right Patient, Right Drug, Right Dose, Right Route, and Right Time.*"
                )

        # 2. General Medicine & Pharmacy Queries
        if any(kw in q_lower for kw in ["medicine", "medication", "pill", "drug", "dose", "prescription", "pharmacy"]):
            return (
                "💊 **Medication Administration & Safety Standards**:\n\n"
                "1. **5 Rights of Medication**: Verify Right Patient, Right Drug, Right Dose, Right Route, and Right Time.\n"
                "2. **Missed Dose Rule**: Administer missed dose as soon as remembered unless it is almost time for the next scheduled dose. Never double doses.\n"
                "3. **Storage**: Store in a cool, dry place away from direct sunlight. Insulin must be refrigerated prior to first use.\n"
                "4. **Interactions**: Always check blood thinners (Warfarin/Eliquis), NSAIDs (Ibuprofen/Aspirin), and blood pressure drugs for interactions.\n\n"
                "*(You can ask me about specific drugs like Paracetamol, Ibuprofen, Amlodipine, Lisinopril, Metformin, Insulin, Aspirin, Atorvastatin, Nitroglycerin, or Donepezil!)*"
            )

        # 3. Medical Vitals & Diagnostics
        elif any(kw in q_lower for kw in ["vitals", "normal range", "blood pressure", "bp", "pulse", "heart rate", "spo2", "oxygen", "temperature"]):
            return (
                "🩺 **Senior Medical Vitals Normal Reference Ranges**:\n\n"
                "• **Blood Pressure**: Normal <120/80 mmHg. Stage 1: 130-139 / 80-89. Hypertensive crisis: >180/120 (Requires Immediate SOS Alert).\n"
                "• **Heart Rate (Pulse)**: 60 - 100 beats per minute (bpm) at rest.\n"
                "• **Oxygen Saturation (SpO2)**: 95% - 100% on room air. (Below 92% requires supplemental oxygen / medical evaluation).\n"
                "• **Body Temperature**: 97.8°F to 99.1°F (36.5°C to 37.3°C).\n"
                "• **Blood Glucose**: Fasting 70-99 mg/dL. Post-prandial <140 mg/dL."
            )

        # 4. Emergency Protocols (Heart attack, Stroke, CPR, Fall, Seizure)
        elif any(kw in q_lower for kw in ["stroke", "fast"]):
            return (
                "🧠 **Stroke Emergency Protocol (F.A.S.T.)**:\n\n"
                "• **F - Face**: Ask resident to smile. Does one side of the face droop?\n"
                "• **A - Arms**: Ask resident to raise both arms. Does one arm drift downward?\n"
                "• **S - Speech**: Ask resident to repeat a simple sentence. Is speech slurred or strange?\n"
                "• **T - Time**: Call 911 & Press CareConnect SOS immediately! Time is brain function."
            )
        elif any(kw in q_lower for kw in ["heart attack", "chest pain", "cardiac"]):
            return (
                "🚨 **Cardiac Emergency Protocol**:\n\n"
                "1. Have resident sit down and stay calm in a comfortable position.\n"
                "2. Loosen tight clothing around neck and chest.\n"
                "3. If prescribed Nitroglycerin, assist with sublingual dose.\n"
                "4. If not allergic, give 325mg Aspirin to chew.\n"
                "5. Press red CareConnect SOS button immediately to alert Security & EMT responders."
            )
        elif any(kw in q_lower for kw in ["fall", "fell", "spinal"]):
            return (
                "🚨 **Fall Emergency Protocol**:\n\n"
                "1. Do NOT force resident to stand up immediately if severe pain, hip pain, or spinal trauma is suspected.\n"
                "2. Check consciousness, breathing, and head injuries.\n"
                "3. Keep resident warm with a blanket.\n"
                "4. Trigger CareConnect SOS panic alert for responder assistance."
            )
        elif any(kw in q_lower for kw in ["seizure", "fit", "convulsion"]):
            return (
                "⚡ **Seizure Emergency Management**:\n\n"
                "1. Gently turn resident onto their side to keep airway clear (recovery position).\n"
                "2. Clear hard or sharp objects away from head.\n"
                "3. Do NOT put anything in the resident's mouth.\n"
                "4. Time the seizure duration. If >5 minutes, press SOS panic button immediately."
            )
        elif any(kw in q_lower for kw in ["diabetes", "hypoglycemia", "low blood sugar", "sugar"]):
            return (
                "🍬 **Hypoglycemia (Low Blood Sugar <70 mg/dL) Rule of 15**:\n\n"
                "1. Give **15 grams of fast-acting carbs** (4 oz fruit juice, 3-4 glucose tablets, or 1 tbsp sugar/honey).\n"
                "2. Wait **15 minutes** and re-check blood glucose.\n"
                "3. If still <70 mg/dL, repeat with another 15g of sugar."
            )
        elif any(kw in q_lower for kw in ["dementia", "alzheimer", "memory", "wandering"]):
            return (
                "🧠 **Dementia & Cognitive Care Best Practices**:\n\n"
                "1. Maintain a consistent daily routine for meals, activities, and rest.\n"
                "2. Speak in simple, reassuring, short sentences with a calm tone.\n"
                "3. Use visual cues (large wall clocks, memory boards, photos).\n"
                "4. Gently redirect agitation or wandering without arguing or confrontation."
            )

        # 5. CareConnect Application & Features Knowledge Base
        elif any(kw in q_lower for kw in ["app", "careconnect", "how to use", "feature", "portal", "role"]):
            return (
                "📱 **CareConnect Platform Architecture & Features**:\n\n"
                "CareConnect features **6 specialized role portals**:\n"
                "• 🚨 **Resident SOS**: One-tap emergency SOS triggering, dispatch tracking, medical profile, and AI risk classifier.\n"
                "• 🛡️ **Responders & Security**: Live emergency incident feed, one-click incident acceptance, turn-by-turn Leaflet/OSRM map navigation.\n"
                "• 💓 **Neighbor Network**: Community alert network enabling nearby volunteers to accept & provide rapid help.\n"
                "• 📞 **Guardians**: Real-time notifications when a ward triggers an SOS & direct caregiver contact details.\n"
                "• 📋 **Caregiver Roster**: Daily resident roster, vital sensor telemetry (heart rate, fall sensors), and AI note analysis.\n"
                "• 📊 **Admin Analytics**: Command center, dispatch override, response time analytics, and directory management."
            )

        elif any(kw in q_lower for kw in ["sos", "button", "trigger", "alarm"]):
            return (
                "🚨 **CareConnect Emergency SOS System**:\n\n"
                "• Pressing the high-contrast red **SOS** button on your Resident dashboard or Navbar instantly broadcasts your location coordinates & medical profile to active Security Responders, Volunteer Responders, and alerts family Guardians via automated dispatch."
            )

        # 6. General Care & Medical Fallback
        else:
            return (
                f"🤖 **CarePulse AI Medical & App Intelligence**:\n\n"
                f"I processed your query: *'{query}'*.\n\n"
                f"I can assist you with:\n"
                f"• **Medicines & Dosages**: Paracetamol, Ibuprofen, Amlodipine, Lisinopril, Metformin, Insulin, Aspirin, Atorvastatin, Nitroglycerin, Warfarin, Donepezil, etc.\n"
                f"• **Medical Emergencies**: Stroke (F.A.S.T.), Cardiac Arrest, Fall Protocols, Seizure Management, Hypoglycemia, Asthma.\n"
                f"• **Vitals & Clinical Standards**: Normal ranges for Blood Pressure, SpO2, Heart Rate, Glucose.\n"
                f"• **CareConnect App**: 6 Role Portals, SOS Dispatch, Leaflet GPS Navigation, Admin Command Center.\n\n"
                f"*For acute medical distress, please press the red **SOS** button immediately.*"
            )

ai_service = AIAgentService()
