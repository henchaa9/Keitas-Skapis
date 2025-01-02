
import SwiftUI

// MARK: - Skats, kas satur lietotāja instrukciju
struct HelpView: View {
    // MARK: - Vides mainīgie
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Apģērbu / Kategoriju pievienošana
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Apģērbu / Kategoriju pievienošana")
                            .font(.title3)
                            .bold()

                        Text("""
                            Lai pievienotu jaunu kategoriju vai apģērbu, spiediet "+", kas atrodas "Sākums" sadaļas augšdaļā, un izvēlieties vēlamo opciju. Pēc tam, pievienojiet foto, aizpildiet pārējos laukus un spiediet "Apstiprināt". Jūsu pievienotā kategorija vai attēls būs redzams sākumlapā.
                        """)
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    // Filtrēšana
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Apģērbu Filtrēšana")
                            .font(.title3)
                            .bold()

                        Text("""
                            Pēc noklusējuma, sākumlapā tiek rādīti visi apģērbi. Lai rādītu konkrētas kategorijas vai vairāku kategoriju apģērbus, piespiediet uz kategorijām, kuras vēlaties redzēt. Attēlu sadaļā ir arī meklēšanas lauks, kurā iespējams meklēt attēlus pēc to nosaukuma, un blakus tam, filtru izvēlne.
                        """)
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    // Apģērbu pievienošana dienai
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Apģērbu pievienošana dienai")
                            .font(.title3)
                            .bold()

                        Text("""
                            Uzspiežot uz apģērba, tiks parādīts detalizēts apģērba skats ar tā parametriem, kā arī poga apģērba izvēlei. Piespiežot šo pogu, tas tiks pievienots izvēlētajiem apģērbiem, kurus iespējams redzēt "Izvēlētie" sadaļā. Šajā sadaļā iespējams pievienot piezīmes un izvēlēties datumu, kuram šos apģērbus pievienot. Piemēram, izvēloties tērpu kādai dienai, vai plānojot uz priekšu, pievienojiet tos attiecīgajai dienai, lai vēlāk redzētu, ko esat vilkuši, ko plānojiet vilkt, kā arī katram apģērbam redzētu, kad tas pēdējoreiz vilkts. "Kalendārs" sadaļā tiks iekrāsotas dienas, kurās ir pievienoti apģērbi un/vai piezīmes. Uzspiežot uz attiecīgās dienas, tos būs iespējams apskatīt, kā arī dzēst no šīs dienas (pavelkot pa kreisi pie apģērba parādīsies dzēšanas poga) vai pievienot vēl apģērbus. Apģērba detalizētajā skatā atrodas arī sirds poga, kura pievienos apģērbu mīļākajiem apģērbiem (redzami "Mīļākie" sadaļā), lai tos varētu ātri atrast.
                        """)
                            .font(.body)
                    }

                    Spacer()
                    
                    // Rediģēšana / Dzēšana
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Apģērbu / Kategoriju rediģēšana un dzēšana")
                            .font(.title3)
                            .bold()

                        Text("""
                            Apgērba detalizētajā skatā atrodas pogas apģērba rediģēšanai vai dzēšanai. Lai redzētu rediģēšanas un dzēšanas opcijas kategorijām, piespiediet un turiet uz kategorijas. Iespējams arī izvēlēties vairākus attēlus uzreiz, turot uz kāda attēla un pēc tam atlasot citus apģērbus. Kad attēli ir atlasīti, ekrāna augšdaļā parādīsies zīmuļa ikona, kuru piespiežot būs redzamas opcijas tos izdzēst, vai mainīt to stāvokli.
                        """)
                            .font(.body)
                    }

                    Spacer()
                    
                    // Netīrie / Mazgāšana
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Netīrie apģērbi / Mazgāšana")
                            .font(.title3)
                            .bold()

                        Text("""
                            Gan apģērba detalizētajā skatā, gan atlasot vairākus apģērbus, iespējams mainīt to stāvokli starp tīrs/netīrs/mazgājas. Redzēt visus netīros vai mazgāšanā esošos apģērbus iespējams sadaļā "Netīrie".
                        """)
                            .font(.body)
                    }
                    
                    Spacer()
                }
                Spacer()
                VStack(alignment: .center) {
                    Text("Keitai").font(.headline)
                    Text("2024").font(.headline)
                }
            }
            .padding()
            .navigationTitle("Lietošanas Instrukcija")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Aizvērt") {
                        dismiss()
                    }
                }
            }
            .background(Color(.systemGray6))
        }
    }
}
