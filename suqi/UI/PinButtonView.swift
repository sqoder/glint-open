//
//  PinButtonView.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI
import AppKit

public struct PinButtonView: View {
    @ObservedObject public var model: SuqiWindowModel
    @State private var isAreaHovered: Bool = false
    @State private var isButtonHovered: Bool = false

    public init(model: SuqiWindowModel) {
        self.model = model
    }

    private var shouldShow: Bool {
        isAreaHovered || isButtonHovered || model.isPinned
    }

    private var pinColor: Color {
        if model.isPinned {
            return Color(red: 1.0, green: 0.74, blue: 0.32)
        } else if isButtonHovered {
            return Color.white.opacity(0.95)
        } else {
            return Color.white.opacity(0.60)
        }
    }

    private var backgroundFill: Color {
        if model.isPinned {
            return Color.white.opacity(0.18)
        } else if isButtonHovered {
            return Color.white.opacity(0.14)
        } else {
            return Color.white.opacity(0.05)
        }
    }

    private var borderStroke: Color {
        if model.isPinned {
            return Color(red: 1.0, green: 0.74, blue: 0.32).opacity(0.40)
        } else if isButtonHovered {
            return Color.white.opacity(0.12)
        } else {
            return Color.white.opacity(0.03)
        }
    }

    public var body: some View {
        ZStack {
            // Invisible hover trigger area in the top-right corner
            Color.clear
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
                .onHover { isAreaHovered = $0 }

            Button {
                model.togglePin()
            } label: {
                buttonContent
            }
            .buttonStyle(.plain)
            .onHover { isButtonHovered = $0 }
            .opacity(shouldShow ? 1.0 : 0.0)
            .scaleEffect(shouldShow ? 1.0 : 0.82)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: shouldShow)
            .animation(.spring(response: 0.25, dampingFraction: 0.70), value: model.isPinned)
            .help(model.isPinned ? "Unpin Window (Click to restore normal level)" : "Pin Window on Top (Always on Top)")
        }
    }

    private var buttonContent: some View {
        Image(systemName: model.isPinned ? "pin.fill" : "pin")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(pinColor)
            .rotationEffect(.degrees(model.isPinned ? -35 : 0))
            .frame(width: 22, height: 22)
            .background(
                Circle()
                    .fill(backgroundFill)
                    .overlay(
                        Circle()
                            .strokeBorder(borderStroke, lineWidth: 0.5)
                    )
                    .shadow(color: model.isPinned ? Color.orange.opacity(0.35) : Color.clear, radius: 2)
            )
    }
}
