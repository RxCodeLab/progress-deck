# Line colours in published two-group cumulative incidence and Kaplan-Meier figures

A survey made for this skill in November 2026, to choose the default colours of `templates/cum_incidence.R`. It covers 35 research papers from 2023-2026 with a two-group Kaplan-Meier or cumulative incidence curve in the main text: 15 from Annals of Internal Medicine and 5 each from NEJM, JAMA, the Lancet and BMJ. The papers were picked from journal searches for those curves, not for their colours, so this is a purposive sample, not a census. One figure was taken per paper, and the colours are pixel samples from the publisher's final image, so the hex values carry some compression and antialiasing noise.

## Tally of line-colour pairs

| Pair | Annals | NEJM | JAMA | Lancet | BMJ |
|---|---:|---:|---:|---:|---:|
| Black + black (solid vs dashed or dotted) | 11 | | | | |
| Black + teal | 2 | | | | |
| Black + mint green | 1 | | | | |
| Red + green | 1 | | | | |
| Grey + orange | | 2 | | | |
| Blue + orange | | 3 | | | 3 |
| Dark teal + orange (`#2F5763` / `#F7941D` in all five) | | | 5 | | |
| Purple + orange | | | | | 2 |
| Blue + red | | | | 5 | |

JAMA's instructions say all figures are re-created by its graphics staff in its own palette, and Annals restyles figures in house, so the colours in those journals are the journal's, not the authors'. Neither ggplot2's default hues nor CohortMethod's pure red and blue appeared.

## Figures

| Journal | First author, year | Study | DOI | Figure | Line 1 | Line 2 | CIs on the curves |
|---|---|---|---|---|---|---|---|
| Annals | Andersson 2024 | Hyponatremia; target trial emulations | 10.7326/M23-1989 | 2 | BFZ / HCTZ–RASi; solid; black `#161713` | CCB / RASi; dashed; teal `#72A0A2` | 95% shaded bands, grey and pale teal |
| Annals | Richman 2023 | Mammography overdiagnosis; cohort | 10.7326/M23-0133 | 2 | Screened; dotted; black `#101A21` | Not screened; solid; black `#1C1D20` | 95% shaded bands; darker and lighter teal, despite both lines being near black |
| Annals | Seib 2023 | Parathyroidectomy and kidney function; target trial emulation | 10.7326/M22-2222 | 2 | Parathyroidectomy; dotted; black `#000000` | Nonoperative management; solid; black `#151515` | None on curves |
| Annals | Wang 2024 | Semaglutide and tobacco use disorder; target trial emulations | 10.7326/M23-2718 | 3 | Insulin / other antidiabetic comparators; dotted; black `#000000` | Semaglutide; solid; black `#000000` | Shaded bands; darker and lighter mint. Seven two-group panels |
| Annals | Rahman 2024 | Gabapentinoids and COPD exacerbation; matched cohort | 10.7326/M23-0849 | 1 | Gabapentinoid use; solid; black `#231F20` | Nonuse; dotted; black `#231F20` | None on curves |
| Annals | Xu 2024 | Statin primary prevention in older adults; target trial emulation | 10.7326/M24-0004 | 3 | Statin noninitiators; solid; black `#000000` | Statin initiators; dotted; black `#000000` | None on curves; numerical CIs in annotations |
| Annals | Heijman 2023 | Joint replacement; secondary analysis of colchicine RCT | 10.7326/M23-0289 | unnumbered | Placebo; solid; black `#000000` | Colchicine; dashed; black `#000000` | Shaded bands; light and dark mint |
| Annals | McQuilten 2023 | Anemia; secondary analysis of ASPREE RCT | 10.7326/M23-0675 | 2 | Placebo; solid; black `#231F20` | Aspirin; dotted; black `#231F20` | None on curves |
| Annals | Jay 2026 | Violence intervention; target trial emulation | 10.7326/ANNALS-25-01678 | 2 | Control; dashed; black `#231F20` | Treatment; solid; teal `#73A4A8` | 95% vertical error bars at 1, 2, 3 years; no ribbon |
| Annals | Ruiz-Canela 2025 | Diabetes prevention; secondary analysis of PREDIMED-Plus RCT | 10.7326/ANNALS-25-00388 | 2 | Control; solid; red `#B52947` | Intervention; solid; green `#0F7B3E` | 95% shaded pink and green bands |
| Annals | Coronado 2025 | Colonoscopy navigation; RCT | 10.7326/ANNALS-24-01885 | 2 | Patient navigation; dashed; black `#141414` | Usual care; solid; black `#161616` | None on curves; numerical restricted-mean-time CIs in annotations |
| Annals | Khalili 2025 | Microscopic colitis; six target trial emulations | 10.7326/ANNALS-25-00268 | 1 | NSAIDs / other studied medications; solid; mint green `#58B394` | None / active comparator; dotted; black `#000000` | None on curves |
| Annals | Evering 2023 | Amubarvimab plus romlusevimab; RCT | 10.7326/M22-3428 | 2 | Amubarvimab plus romlusevimab; solid; black `#1B1B1B` | Placebo; dashed; black `#1D1D1D` | None on curves; open circles are censoring marks |
| Annals | Edelstein 2023 | Nirmatrelvir–ritonavir virologic rebound; cohort | 10.7326/M23-1756 | 3 | Nirmatrelvir–ritonavir; solid; black `#000000` | No therapy; dotted; black `#000000` | None on curves; censoring ticks |
| Annals | Zhou 2024 | Atorvastatin versus rosuvastatin; cohort | 10.7326/M24-0178 | 2 | Atorvastatin; dashed; black `#000000` | Rosuvastatin; solid; black `#000000` | 95% vertical error bars at selected times; no ribbon |
| NEJM | Lincoff 2023 | SELECT; RCT | 10.1056/NEJMoa2307563 | 1 | Semaglutide; solid; orange `#EB9F3D` | Placebo; solid; grey `#ABAEB3` | None on curves |
| NEJM | Perkovic 2024 | FLOW; RCT | 10.1056/NEJMoa2403347 | 1 | Semaglutide; solid; orange `#E6A53F` | Placebo; solid; grey `#818588` | None on curves |
| NEJM | Carson 2023 | MINT; RCT | 10.1056/NEJMoa2307983 | 3 | Restrictive strategy; solid; blue `#6189C7` | Liberal strategy; solid; orange `#EAA041` | None on curves |
| NEJM | Møller 2024 | DanGer-Shock; RCT | 10.1056/NEJMoa2312572 | 1 | Standard care alone; solid; blue `#5B88C1` | Microaxial flow pump plus standard care; solid; orange `#E29D3E` | Shaded confidence bands |
| NEJM | Solomon 2024 | FINEARTS-HF; RCT, cardiovascular death panel | 10.1056/NEJMoa2407107 | 1C | Placebo; solid; blue `#6189C4` | Finerenone; solid; orange `#E8A240` | None on curves |
| JAMA | Limaye 2023 | CMV prophylaxis; RCT, event-free survival | 10.1001/jama.2023.9106 | 3 | Letermovir; solid; teal `#2F5763` | Valganciclovir; solid; orange `#F7941D` | None on survival curves; forest-plot CIs in panel A are separate |
| JAMA | Monti 2023 | MERCY; RCT | 10.1001/jama.2023.10598 | 2 | Continuous meropenem; solid; teal `#2F5763` | Intermittent meropenem; solid; orange `#F7941D` | None on curves |
| JAMA | Hwang 2025 | COMET; RCT | 10.1001/jama.2024.26698 | 2 | Guideline-concordant care; solid; teal `#2F5763` | Active monitoring; solid; orange `#F7941D` | 95% shaded bands |
| JAMA | HARMONi-A Study Investigators / Fang 2024 | HARMONi-A; RCT | 10.1001/jama.2024.10613 | 2 | Ivonescimab plus chemotherapy; solid; teal `#2F5763` | Placebo plus chemotherapy; solid; orange `#F7941D` | None on curves; censoring ticks |
| JAMA | Liang 2025 | DIPPER; RCT | 10.1001/jama.2025.1132 | 2 | Standard therapy; solid; teal `#2F5763` | Camrelizumab; solid; orange `#F7941D` | None on curves; censoring ticks |
| Lancet | Park 2024 | PREVENT; RCT | 10.1016/S0140-6736(24)00413-6 | 200413-6/asset/96c98c16-28d9-4e4e-ac1e-dee7e5a4844c/main.assets/gr2_lrg.jpg) | Optimal medical therapy alone; solid; cyan-blue `#15A3C7` | Preventive PCI plus optimal medical therapy; solid; red `#BA2855` | None on curves |
| Lancet | Yau 2025 | CheckMate 9DW; RCT | 10.1016/S0140-6736(25)00403-9 | 2A00403-9/asset/06c0bccf-4414-4138-b9f7-8810aac58258/main.assets/gr2_lrg.jpg) | Nivolumab plus ipilimumab; solid; blue `#0A53A2` | Lenvatinib or sorafenib; solid; red `#F12C24` | None on survival curves; forest-plot CIs in panel B are separate |
| Lancet | Harada-Shoji 2026 | J-START; secondary analysis of RCT | 10.1016/S0140-6736(25)02319-0 | 202319-0/asset/7cbe917d-700b-4997-8f3c-576e067b53dd/main.assets/gr2_lrg.jpg) | Control (mammography); solid; cyan-blue `#23A8CB` | Study group (mammography plus ultrasonography); solid; red `#C22C59` | None on curves; vertical dashed lines mark screening times |
| Lancet | Lewis 2025 | ENRICH; RCT | 10.1016/S0140-6736(25)01432-1 | 201432-1/asset/37c89604-a20e-436e-bfc4-673386175a20/main.assets/gr2_lrg.jpg) | Immunochemotherapy; solid; cyan-blue `#00A2BB` | Ibrutinib–rituximab; solid; red `#AE0735` | Shaded bands; censoring ticks |
| Lancet | Janjigian 2023 | KEYNOTE-811; RCT | 10.1016/S0140-6736(23)02033-0 | 202033-0/asset/1c252fb5-492f-4d2b-b508-738e27973bfa/main.assets/gr2_lrg.jpg) | Pembrolizumab group; solid; cyan-blue `#0DA1C9` | Placebo group; solid; red `#B40936` | None on curves; censoring ticks |
| BMJ | Ma 2023 | PHILA; RCT | 10.1136/bmj-2023-076065 | 2 | Pyrotinib group; solid; purple `#6A5EAA` | Placebo group; dashed; orange `#F6AA32` | None on curves; censoring ticks |
| BMJ | Tian 2025 | PATENCY; RCT follow-up | 10.1136/bmj-2024-082883 | 2 | No-touch group; solid; blue `#397EB5` | Conventional group; solid; orange `#F6AD2A` | Shaded bands |
| BMJ | Qiu 2024 | RATIONALE-305; RCT | 10.1136/bmj-2023-078876 | 2 | Tislelizumab plus chemotherapy; solid; blue `#196DAD` | Placebo plus chemotherapy; solid; orange `#F6B847` | None on curves; dashed vertical guides are not CIs |
| BMJ | Gao 2025 | REC-CAGEFREE II; RCT | 10.1136/bmj-2024-082945 | 2 | Standard DAPT; solid; blue `#3469AD` | Stepwise DAPT de-escalation; solid; orange `#F2AA00` | None on curves; circles are censoring marks |
| BMJ | Xie 2023 | Nirmatrelvir and admission/death; target trial emulation | 10.1136/bmj-2022-073312 | 3 | No treatment; solid; purple `#675C94` | Nirmatrelvir; dashed; orange `#F4B331` | Shaded bands; vertical grey block marks treatment-initiation period |
