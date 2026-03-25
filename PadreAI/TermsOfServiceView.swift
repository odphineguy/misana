//
//  TermsOfServiceView.swift
//  MiSana
//
//  Created by Abe Perez on 3/25/26.
//

import SwiftUI

struct TermsOfServiceView: View {
    let selectedLanguage: AppLanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedLanguage == .spanish ?
                             "Terminos de Servicio de MiSana" :
                             "MiSana Terms of Service")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(selectedLanguage == .spanish ?
                             "Por favor lee estos terminos cuidadosamente antes de usar MiSana." :
                             "Please read these terms carefully before using MiSana.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Section 1
                    sectionHeader(selectedLanguage == .spanish ?
                                  "1. Aceptacion de los terminos" :
                                  "1. Acceptance of Terms")
                    Text(selectedLanguage == .spanish ?
                         "Al descargar, instalar o usar MiSana, aceptas estos Terminos de Servicio. Si no estas de acuerdo, no uses la aplicacion." :
                         "By downloading, installing, or using MiSana, you agree to be bound by these Terms of Service. If you do not agree, do not use the app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Section 2
                    sectionHeader(selectedLanguage == .spanish ?
                                  "2. Descripcion del servicio" :
                                  "2. Description of Service")
                    Text(selectedLanguage == .spanish ?
                         "MiSana es una aplicacion bilingue de salud que proporciona informacion general de salud, seguimiento de medicamentos, revision de sintomas y herramientas de preparacion para citas medicas. MiSana usa un modelo de IA en el dispositivo para procesar tus consultas localmente en tu iPhone." :
                         "MiSana is a bilingual health companion app that provides general health information, medication tracking, symptom checking, and appointment preparation tools. MiSana uses an on-device AI model to process your queries locally on your iPhone.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Section 3
                    sectionHeader(selectedLanguage == .spanish ?
                                  "3. No es consejo medico" :
                                  "3. Not Medical Advice")
                    Text(selectedLanguage == .spanish ?
                         "MiSana NO es un profesional medico, doctor ni proveedor de salud. La aplicacion proporciona contenido educativo e informativo general solamente. MiSana no:" :
                         "MiSana is NOT a medical professional, doctor, or healthcare provider. The app provides general educational and informational content only. MiSana does not:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    bulletList(selectedLanguage == .spanish ?
                        ["Diagnostica enfermedades ni condiciones medicas",
                         "Receta tratamientos ni medicamentos",
                         "Reemplaza el consejo medico profesional",
                         "Proporciona servicios medicos de emergencia"] :
                        ["Diagnose diseases or medical conditions",
                         "Prescribe treatments or medications",
                         "Replace professional medical advice",
                         "Provide emergency medical services"])
                    Text(selectedLanguage == .spanish ?
                         "Siempre consulta con un profesional de salud calificado para decisiones medicas. En caso de emergencia medica, llama al 911 inmediatamente." :
                         "Always consult a qualified healthcare professional for medical decisions. In case of a medical emergency, call 911 immediately.")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    // Section 4
                    sectionHeader(selectedLanguage == .spanish ?
                                  "4. Responsabilidades del usuario" :
                                  "4. User Responsibilities")
                    Text(selectedLanguage == .spanish ?
                         "Eres responsable de:" :
                         "You are responsible for:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    bulletList(selectedLanguage == .spanish ?
                        ["Usar MiSana como herramienta informativa complementaria, no como sustituto de atencion medica profesional",
                         "Verificar cualquier informacion de salud con un profesional de salud calificado",
                         "Mantener la seguridad de tu dispositivo, ya que MiSana almacena datos localmente",
                         "Cumplir con el requisito de edad minima (13 anos o mas)"] :
                        ["Using MiSana as a supplementary informational tool, not as a substitute for professional medical care",
                         "Verifying any health information with a qualified healthcare provider",
                         "Maintaining the security of your device, as MiSana stores data locally",
                         "Ensuring you meet the minimum age requirement (13 years or older)"])

                    // Section 5
                    sectionHeader(selectedLanguage == .spanish ?
                                  "5. Contenido generado por IA" :
                                  "5. AI-Generated Content")
                    Text(selectedLanguage == .spanish ?
                         "MiSana usa inteligencia artificial para generar respuestas. El contenido generado por IA puede contener inexactitudes. Reconoces que:" :
                         "MiSana uses artificial intelligence to generate responses. AI-generated content may contain inaccuracies. You acknowledge that:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    bulletList(selectedLanguage == .spanish ?
                        ["Las respuestas de IA no son verificadas por profesionales medicos",
                         "El modelo de IA funciona localmente y sus resultados dependen de los datos de entrenamiento del modelo",
                         "No debes depender unicamente del contenido generado por IA para decisiones de salud"] :
                        ["AI responses are not verified by medical professionals",
                         "The AI model runs locally and its outputs depend on the model's training data",
                         "You should not rely solely on AI-generated content for health decisions"])

                    // Section 6
                    sectionHeader(selectedLanguage == .spanish ?
                                  "6. Datos de HealthKit" :
                                  "6. HealthKit Data")
                    Text(selectedLanguage == .spanish ?
                         "Si le otorgas acceso a MiSana a los datos de Apple HealthKit, reconoces que estos datos se usan unicamente para proporcionar resumenes de salud personalizados dentro de la aplicacion. Todos los datos de HealthKit se procesan en el dispositivo y nunca se transmiten. Puedes revocar el acceso en cualquier momento a traves de los ajustes de tu dispositivo." :
                         "If you grant MiSana access to Apple HealthKit data, you acknowledge that this data is used solely to provide personalized health summaries within the app. All HealthKit data is processed on-device and never transmitted. You can revoke access at any time through your device settings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Section 7
                    sectionHeader(selectedLanguage == .spanish ?
                                  "7. Propiedad intelectual" :
                                  "7. Intellectual Property")
                    Text(selectedLanguage == .spanish ?
                         "MiSana, incluyendo su diseno, codigo y contenido, es propiedad de su desarrollador. Se te otorga una licencia limitada, no exclusiva e intransferible para usar la aplicacion con fines personales y no comerciales." :
                         "MiSana, including its design, code, and content, is the property of its developer. You are granted a limited, non-exclusive, non-transferable license to use the app for personal, non-commercial purposes.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Section 8
                    sectionHeader(selectedLanguage == .spanish ?
                                  "8. Limitacion de responsabilidad" :
                                  "8. Limitation of Liability")
                    Text(selectedLanguage == .spanish ?
                         "En la medida maxima permitida por la ley, MiSana y su desarrollador no seran responsables de danos directos, indirectos, incidentales, especiales o consecuentes derivados de tu uso de la aplicacion, incluyendo pero no limitado a danos relacionados con decisiones de salud tomadas basandose en informacion proporcionada por la aplicacion." :
                         "To the maximum extent permitted by law, MiSana and its developer shall not be liable for any direct, indirect, incidental, special, or consequential damages arising from your use of the app, including but not limited to damages related to health decisions made based on information provided by the app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Section 9
                    sectionHeader(selectedLanguage == .spanish ?
                                  "9. Descargo de garantias" :
                                  "9. Disclaimer of Warranties")
                    Text(selectedLanguage == .spanish ?
                         "MiSana se proporciona \"tal cual\" sin garantias de ningun tipo, ya sean expresas o implicitas. No garantizamos que la aplicacion sera libre de errores, ininterrumpida, o que la informacion proporcionada sera precisa o completa." :
                         "MiSana is provided \"as is\" without warranties of any kind, either express or implied. We do not warrant that the app will be error-free, uninterrupted, or that the information provided will be accurate or complete.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Section 10
                    sectionHeader(selectedLanguage == .spanish ?
                                  "10. Terminacion" :
                                  "10. Termination")
                    Text(selectedLanguage == .spanish ?
                         "Puedes dejar de usar MiSana en cualquier momento eliminando la aplicacion de tu dispositivo. Nos reservamos el derecho de descontinuar la aplicacion o modificar sus funciones en cualquier momento." :
                         "You may stop using MiSana at any time by deleting the app from your device. We reserve the right to discontinue the app or modify its features at any time.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Section 11
                    sectionHeader(selectedLanguage == .spanish ?
                                  "11. Cambios a los terminos" :
                                  "11. Changes to Terms")
                    Text(selectedLanguage == .spanish ?
                         "Podemos actualizar estos terminos de vez en cuando. El uso continuado de la aplicacion despues de los cambios constituye la aceptacion de los nuevos terminos. Cambios significativos seran comunicados mediante una actualizacion de la aplicacion." :
                         "We may update these terms from time to time. Continued use of the app after changes constitutes acceptance of the new terms. Significant changes will be communicated through an app update.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Section 12
                    sectionHeader(selectedLanguage == .spanish ?
                                  "12. Ley aplicable" :
                                  "12. Governing Law")
                    Text(selectedLanguage == .spanish ?
                         "Estos terminos se rigen por las leyes de los Estados Unidos de America y el estado donde reside el desarrollador." :
                         "These terms are governed by the laws of the United States of America and the state in which the developer resides.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Section 13
                    sectionHeader(selectedLanguage == .spanish ?
                                  "13. Contacto" :
                                  "13. Contact")
                    Text(selectedLanguage == .spanish ?
                         "Para preguntas sobre estos terminos, contactanos en:" :
                         "For questions about these terms, contact us at:")
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
                             "Terminos de Servicio" :
                             "Terms of Service")
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
