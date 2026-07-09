//
//  SeleccionMusculosView.swift
//  Avoro
//
//  Paso 3/4 del flujo (rama "Un solo día"). Las categorías (Tren
//  superior/inferior/Core) y qué músculo pertenece a cuál son fijas en la
//  UI —tu esquema no guarda esa agrupación—, pero solo se muestran los
//  músculos que de verdad existen en el catálogo (ver
//  SeleccionMusculosViewModel).
//

import SwiftUI

private struct CategoriaMusculo {
    let titulo: String
    let subtitulo: String
    let musculos: [String]
}

struct SeleccionMusculosView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SeleccionMusculosViewModel()
    @State private var seleccionados: Set<String> = []
    @State private var irAPropuesta = false

    private let categorias: [CategoriaMusculo] = [
        CategoriaMusculo(
            titulo: "Tren superior",
            subtitulo: "Pecho, espalda, hombros y brazos",
            musculos: ["Pecho", "Espalda", "Hombro", "Bíceps", "Tríceps"]
        ),
        CategoriaMusculo(
            titulo: "Tren inferior",
            subtitulo: "Piernas y glúteos",
            musculos: ["Cuádriceps", "Femoral", "Glúteo", "Pantorrilla"]
        ),
        CategoriaMusculo(
            titulo: "Core",
            subtitulo: "Abdomen y zona media",
            musculos: ["Abdomen"]
        ),
    ]

    private let columnas = [GridItem(.adaptive(minimum: 100), spacing: 10)]

    var body: some View {
        VStack(spacing: 0) {
            ModoEntrenadorHeader(paso: 3, onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("¿Qué quieres entrenar?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(ProgresaColor.primary)
                        Text("Elige uno o más músculos. Solo puedes combinar músculos de la misma zona.")
                            .font(.subheadline)
                            .foregroundColor(ProgresaColor.textSecondary)
                    }
                    .padding(.top, 8)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        ForEach(categorias, id: \.titulo) { categoria in
                            seccionCategoria(categoria)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 110)
            }
        }
        .background(ProgresaColor.background)
        .navigationBarHidden(true)
        .task {
            await viewModel.cargarGruposMusculares()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Text("\(seleccionados.count) seleccionados")
                    .font(.footnote)
                    .foregroundColor(ProgresaColor.textSecondary)

                Button {
                    irAPropuesta = true
                } label: {
                    Label("Generar rutina", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProgresaPrimaryButtonStyle())
                .disabled(seleccionados.isEmpty)
                .opacity(seleccionados.isEmpty ? 0.5 : 1)
            }
            .padding(16)
            .background(ProgresaColor.surface)
        }
        .navigationDestination(isPresented: $irAPropuesta) {
            RutinaUnDiaPropuestaView(musculosSeleccionados: Array(seleccionados))
        }
    }

    @ViewBuilder
    private func seccionCategoria(_ categoria: CategoriaMusculo) -> some View {
        let musculosDisponibles = categoria.musculos.filter {
            viewModel.gruposDisponibles.contains($0.lowercased())
        }

        if !musculosDisponibles.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(categoria.titulo)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ProgresaColor.primary)
                    Spacer()
                    Text(categoria.subtitulo)
                        .font(.footnote)
                        .foregroundColor(ProgresaColor.textSecondary)
                }

                LazyVGrid(columns: columnas, alignment: .leading, spacing: 10) {
                    ForEach(musculosDisponibles, id: \.self) { musculo in
                        chip(musculo)
                    }
                }
            }
        }
    }

    private func chip(_ musculo: String) -> some View {
        let seleccionado = seleccionados.contains(musculo)
        return Button {
            if seleccionado {
                seleccionados.remove(musculo)
            } else {
                seleccionados.insert(musculo)
            }
        } label: {
            Text(musculo)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(seleccionado ? .white : ProgresaColor.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(seleccionado ? ProgresaColor.primary : ProgresaColor.surface)
                .overlay(
                    Capsule().stroke(ProgresaColor.border, lineWidth: seleccionado ? 0 : 1)
                )
                .clipShape(Capsule())
        }
    }
}

#Preview {
    NavigationStack {
        SeleccionMusculosView()
    }
}
