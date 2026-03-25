//
//  PrivacyPolicyView.swift
//  MiSana
//
//  Created by Abe Perez on 3/25/26.
//

import SwiftUI

struct PrivacyPolicyView: View {
    let selectedLanguage: AppLanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedLanguage == .spanish ?
                             "Politica de Privacidad de MiSana" :
                             "MiSana Privacy Policy")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(selectedLanguage == .spanish ?
                             "Tu salud es privada. Asi la protegemos." :
                             "Your health is private. Here's how we protect it.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Highlight box
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedLanguage == .spanish ?
                             "Lo mas importante:" :
                             "The bottom line:")
                            .fontWeight(.bold)
                        Text(selectedLanguage == .spanish ?
                             "MiSana procesa toda tu informacion directamente en tu dispositivo. Nunca se envian datos a internet. No recopilamos, almacenamos ni compartimos tus datos de salud." :
                             "MiSana processes all your information directly on your device. No data is ever sent to the internet. We do not collect, store, or share your health data.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.brand.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Section 1
                    sectionHeader(selectedLanguage == .spanish ?
                                  "1. Que datos leemos de Apple Salud" :
                                  "1. What data we read from Apple Health")
                    Text(selectedLanguage == .spanish ?
                         "Con tu permiso explicito, MiSana lee (solo lectura) los siguientes datos de HealthKit para darte informacion personalizada:" :
                         "With your explicit permission, MiSana reads (read-only) the following HealthKit data to provide personalized health information:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    bulletList(selectedLanguage == .spanish ?
                        ["Pasos diarios y distancia caminada",
                         "Ritmo cardiaco y ritmo cardiaco en reposo",
                         "Energia activa quemada",
                         "Datos de sueno (duracion, etapas)",
                         "Presion arterial (sistolica/diastolica)",
                         "Oxigeno en sangre (SpO2)",
                         "Peso corporal",
                         "Pisos subidos"] :
                        ["Daily steps and walking distance",
                         "Heart rate and resting heart rate",
                         "Active energy burned",
                         "Sleep data (duration, stages)",
                         "Blood pressure (systolic/diastolic)",
                         "Blood oxygen (SpO2)",
                         "Body weight",
                         "Flights climbed"])
                    Text(selectedLanguage == .spanish ?
                         "MiSana nunca escribe ni modifica tus datos en Apple Salud. El acceso es estrictamente de solo lectura." :
                         "MiSana never writes to or modifies your Apple Health data. Access is strictly read-only.")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    // Section 2
                    sectionHeader(selectedLanguage == .spanish ?
                                  "2. Como procesamos tus datos" :
                                  "2. How we process your data")
                    Text(selectedLanguage == .spanish ?
                         "MiSana utiliza un modelo de inteligencia artificial que funciona completamente en tu iPhone. Esto significa:" :
                         "MiSana uses an artificial intelligence model that runs entirely on your iPhone. This means:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    bulletList(selectedLanguage == .spanish ?
                        ["Tus datos de salud nunca salen de tu dispositivo",
                         "No hay servidores, no hay nube, no hay conexion a internet requerida",
                         "El procesamiento de IA ocurre localmente usando el chip de tu iPhone",
                         "Nadie — ni siquiera nosotros — puede acceder a tus datos de salud"] :
                        ["Your health data never leaves your device",
                         "No servers, no cloud, no internet connection required",
                         "AI processing happens locally using your iPhone's chip",
                         "Nobody — not even us — can access your health data"])

                    // Section 3
                    sectionHeader(selectedLanguage == .spanish ?
                                  "3. Uso de la camara" :
                                  "3. Camera usage")
                    Text(selectedLanguage == .spanish ?
                         "MiSana solicita acceso a la camara unicamente para escanear codigos de barras de medicamentos. Las imagenes de la camara se procesan en el momento y no se almacenan, guardan ni transmiten." :
                         "MiSana requests camera access solely for scanning medication barcodes. Camera images are processed in the moment and are not stored, saved, or transmitted.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Section 4
                    sectionHeader(selectedLanguage == .spanish ?
                                  "4. Lo que NO hacemos" :
                                  "4. What we do NOT do")
                    bulletList(selectedLanguage == .spanish ?
                        ["No recopilamos datos personales ni de salud",
                         "No almacenamos datos en servidores ni en la nube",
                         "No compartimos datos con terceros, anunciantes ni intermediarios de datos",
                         "No usamos datos de salud para publicidad ni mineria de datos",
                         "No creamos cuentas de usuario ni perfiles",
                         "No usamos herramientas de analisis o rastreo de terceros",
                         "No almacenamos informacion personal de salud en iCloud"] :
                        ["We do not collect personal or health data",
                         "We do not store data on servers or the cloud",
                         "We do not share data with third parties, advertisers, or data brokers",
                         "We do not use health data for advertising or data mining",
                         "We do not create user accounts or profiles",
                         "We do not use third-party analytics or tracking tools",
                         "We do not store personal health information in iCloud"])

                    // Section 5
                    sectionHeader(selectedLanguage == .spanish ?
                                  "5. Almacenamiento local" :
                                  "5. Local storage")
                    Text(selectedLanguage == .spanish ?
                         "Las listas de medicamentos y notas que crees dentro de MiSana se guardan localmente en tu dispositivo usando almacenamiento estandar de la aplicacion. Estos datos nunca se transmiten fuera de tu iPhone." :
                         "Medication lists and notes you create within MiSana are stored locally on your device using standard app storage. This data is never transmitted outside your iPhone.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Section 6
                    sectionHeader(selectedLanguage == .spanish ?
                                  "6. Como revocar permisos" :
                                  "6. How to revoke permissions")
                    Text(selectedLanguage == .spanish ?
                         "Puedes revocar el acceso de MiSana a tus datos de Apple Salud en cualquier momento:" :
                         "You can revoke MiSana's access to your Apple Health data at any time:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(selectedLanguage == .spanish ?
                         "Ajustes > Salud > Acceso a Datos y Dispositivos > MiSana" :
                         "Settings > Health > Data Access & Devices > MiSana")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(selectedLanguage == .spanish ?
                         "Revocar el acceso no elimina datos ya almacenados por Apple Salud — solo detiene a MiSana de leerlos." :
                         "Revoking access does not delete data already stored by Apple Health — it only stops MiSana from reading it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Section 7
                    sectionHeader(selectedLanguage == .spanish ?
                                  "7. Aviso medico" :
                                  "7. Medical disclaimer")
                    Text(selectedLanguage == .spanish ?
                         "MiSana no es un profesional medico. La aplicacion proporciona informacion educativa general y no debe usarse para diagnosticar, tratar ni manejar condiciones medicas. Siempre consulta con un profesional de salud calificado." :
                         "MiSana is not a medical professional. The app provides general educational information and should not be used to diagnose, treat, or manage medical conditions. Always consult a qualified healthcare professional.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Section 8
                    sectionHeader(selectedLanguage == .spanish ?
                                  "8. Privacidad de menores" :
                                  "8. Children's privacy")
                    Text(selectedLanguage == .spanish ?
                         "MiSana no esta disenada para menores de 13 anos. No recopilamos informacion de ninos de ninguna manera." :
                         "MiSana is not designed for children under 13. We do not collect information from children in any way.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Section 9
                    sectionHeader(selectedLanguage == .spanish ?
                                  "9. Cambios a esta politica" :
                                  "9. Changes to this policy")
                    Text(selectedLanguage == .spanish ?
                         "Si actualizamos esta politica, publicaremos los cambios en esta pagina con la fecha actualizada. Cambios significativos seran comunicados mediante una actualizacion de la aplicacion." :
                         "If we update this policy, we will post the changes on this page with the updated date. Significant changes will be communicated through an app update.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Section 10
                    sectionHeader(selectedLanguage == .spanish ?
                                  "10. Contacto" :
                                  "10. Contact")
                    Text(selectedLanguage == .spanish ?
                         "Para preguntas sobre privacidad, contactanos en:" :
                         "For privacy questions, contact us at:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("misana.app.privacy@gmail.com")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.brand)

                    // Effective date
                    Divider()
                    Text(selectedLanguage == .spanish ?
                         "Fecha efectiva: 21 de marzo de 2026" :
                         "Effective date: March 21, 2026")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle(selectedLanguage == .spanish ?
                             "Politica de Privacidad" :
                             "Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedLanguage == .spanish ? "Cerrar" : "Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.brand)
    }

    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
