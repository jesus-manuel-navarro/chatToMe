//
//  ConversacionView.swift
//  chatToMe
//
//  Created by Jose on 7/5/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth
import Firebase
import FirebaseStorage

struct ConversacionView: View {
    
    //@ObservedObject private var authModel = AuthViewModel()
    @EnvironmentObject private var authModel: AuthViewModel
    @StateObject var msgViewModel: MensajesViewModel
    @State private var mensaje : String = ""
    @State private var mensajesOrdenados: [Mensaje] = []
    @State private var pepe: [String] = ["hola","compis"]
    @State var mostrarImagenInicial = true
    @FocusState private var focusEnMensaje: Bool
    let storage = Storage.storage()
    
    var body: some View {
        ZStack {//Este ZStack es para mostrar la imagen inicial
            
        if mostrarImagenInicial {
            AnimacionInicialView(mostrarImg: $mostrarImagenInicial)
        }else {
                Group {
                    VStack(alignment: .leading){
                        //Spacer()
                            CabeceraView()
                            //.padding(.top,20)
                            //Controlamos los cambios del array que se carga desde la bbdd, para asignarlos al array ordenado y así poder refrescar la vista
                            .onChange(of: msgViewModel.mensajesDB) { nuevosMensajes in
                                    mensajesOrdenados = nuevosMensajes.sorted(by: { ($0.timestamp?.dateValue() ?? Date()) < ($1.timestamp?.dateValue() ?? Date()) })
                                }
                            //Necesitamos mostrar siempre el último elemento del array, por eso usamos scrollViewReader dentro del ScrollView
    
                            ScrollViewReader { scrollView in //proxy
                                ScrollView {
                                        //Muy importante agregar el id: \.self para que identifique los cambios en el array y se refresque el scroll
                                            ForEach(mensajesOrdenados, id: \.self){  item in
                                                //Imprimo el usuario que ha subido el msg, no el que está loggeado!!
                                                if(item.usuarioE == authModel.user?.email) {
                                                    MostrarMensajes(item: item, color: Color.green, al1: .bottomLeading, al2: .leading,txtColor: Color.black)
                                                }else{
                                                    MostrarMensajes(item: item, color: Color.blue, al1: .bottomTrailing, al2: .trailing,txtColor: Color.white)
                                                }
                                            }
                                            .onChange(of: mensajesOrdenados) { _ in
                                                scrollToBottom(scrollView: scrollView)
                                                }
                                            
                                        }.padding(5)
                                        
                            }
                            //Le insertamos un onCommit, para eliminar botón de enviar mensaje; bastará con pulsar enter
                            TextField("Escribe tu mensaje:", text: $mensaje, onCommit: {
                                let tiempo = Timestamp(date: Date())
                                
                                let msg = Mensaje(texto: mensaje,usuarioE: authModel.user?.email ?? "Vacío",timestamp: tiempo)
                                msgViewModel.addMensaje(mensaje: msg)
                                //msgViewModel.fetchMensajes()
                                //Actualizamos mensajesOrdenados para que el Scroll baje
                                mensajesOrdenados.append(msg)
                                //No hace falta, porque he agregado un onChange al ppio de la vista

                                mensaje = ""
                                focusEnMensaje = true
                            })
                                .focused($focusEnMensaje)//Así el user no tiene que pulsar sobre el textField para poder escribir
                                .padding([.horizontal,.vertical])
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 2)
                                        .shadow(radius: 3)
                                )
                                .padding([.horizontal,.vertical])
                        }
                        
                    .onAppear {
                        focusEnMensaje = true //Ponemos a true esta variable, para que el user no tenga que pulsar sobre el mensaje para poder escribir
                        msgViewModel.fetchMensajes()
                        msgViewModel.startListening()
                        
                        // Utilizamos el método map para obtener un array de String con el campo texto de cada mensaje y ordenados por la marca de tiempo
                        //Cargamos en la variable, los mensajes ordenados
                        mensajesOrdenados = msgViewModel.mensajesDB.sorted(by: { ($0.timestamp?.dateValue() ?? Date()) < ($1.timestamp?.dateValue() ?? Date()) }).map { $0 }
                        //Tampoco hace falta, al agregar el onChange al ppio de la vista
                            }
                    .onDisappear {
                               msgViewModel.stopListening()
                }
                   // .padding(.top,20)
                }
               // .padding(.top,20)
            }
                
        }//Fin ZStack
        //.padding(.top,20)
        .navigationBarTitleDisplayMode(.inline) //para ganar espacio en la parte superior de la vista. Compacta la barra de navegación
        //.navigationBarHidden(true)
        //.padding(.top)
        //.edgesIgnoringSafeArea(.top)
        .background(Image("fondochats").edgesIgnoringSafeArea(.all).opacity(0.4))
        
    }
        

func scrollToBottom(scrollView: ScrollViewProxy) {
        guard let lastMessage = mensajesOrdenados.last else { return }
    withAnimation {
            DispatchQueue.main.async {
                // Utilizamos ScrollViewReader para hacer scroll al último elemento
                scrollView.scrollTo(lastMessage, anchor: .bottom)
            }
        }
    }
}

struct ConversacionView_Previews: PreviewProvider {
    static var previews: some View {
        ConversacionView(msgViewModel: MensajesViewModel(nombreColeccion: "mensajes"))
    }
}

struct MostrarMensajes: View {
    var item : Mensaje
    var color : Color
    var al1 : Alignment
    var al2 : HorizontalAlignment
    var txtColor : Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(" > \(item.usuarioE)")
                .font(.footnote)
            ZStack(alignment: al1) {
                // Fondo azul con el texto del timestamp
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Contenido del mensaje
                
                VStack(alignment: al2) {
                    
                    Text(item.texto)
                        .bold()
                        .padding([.leading, .trailing],5)
                        .foregroundColor(txtColor)
                
                    Text(item.timestamp?.dateValue().formatted() ?? Date().formatted())
                    //.font(.footnote)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding([.leading, .trailing], 5)
                        .padding(.bottom,5)
                }//fin de vstack
            }
            .padding(.horizontal, 5)
            
        }
    }
}

struct AnimacionInicialView: View {
    @Binding var mostrarImg : Bool
    @State private var rotationDegrees: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            ZStack {
                Circle()
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: 151, height: 151)
                
                Image("chatlogo1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                    .frame(width: 150, height: 150)
                    .rotation3DEffect(.degrees(rotationDegrees), axis: (x: 0, y: 1, z: 0))
                    .onAppear {
                        // Ocultamos la imagen inicial después de 2 segundos
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            mostrarImg = false
                        }
                        // Inicia la animación de rotación
                        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                            withAnimation(.linear(duration: 2)) {
                                rotationDegrees += 3
                            }
                        }
                    }
            }
        }

       /* Color.black.edgesIgnoringSafeArea(.all)
        Image("chatlogo1")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .onAppear {
            // Ocultamos la imagen inicial después de 2 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                mostrarImg = false
            }
        }*/
    }
}
