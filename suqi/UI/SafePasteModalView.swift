//
//  SafePasteModalView.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI

public struct SafePasteModalView: View {
    let request: SafePasteRequest
    @ObservedObject var model: SuqiWindowModel

    public init(request: SafePasteRequest, model: SuqiWindowModel) {
        self.request = request
        self.model = model
    }

    public var body: some View {
        ZStack {
            // Dark dimming backdrop
            Color.black.opacity(0.50)
                .ignoresSafeArea()
                .onTapGesture {
                    model.cancelSafePaste()
                }

            // Modal dialog card
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(spacing: 10) {
                    Image(systemName: request.isDangerous ? "exclamationmark.octagon.fill" : "shield.lefthalf.filled")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(request.isDangerous ? Color.red : Color.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(request.isDangerous ? "危险命令安全拦截" : "多行命令粘贴确认")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)

                        Text(request.reason)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.70))
                            .lineLimit(2)
                    }

                    Spacer()

                    Button {
                        model.cancelSafePaste()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.60))
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }

                // Command Preview Box
                ScrollView(.vertical, showsIndicators: true) {
                    Text(request.text)
                        .font(.system(size: 11.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.90))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .frame(maxHeight: 140)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.black.opacity(0.40))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )

                // Actions Footer
                HStack(spacing: 8) {
                    Spacer()

                    // Cancel
                    Button {
                        model.cancelSafePaste()
                    } label: {
                        Text("取消 (Esc)")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5.5)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)

                    // Single line option for multiline pastes
                    if request.lineCount >= 2 {
                        Button {
                            model.confirmSafePaste(asSingleLine: true)
                        } label: {
                            Text("单行粘贴 (⌥↩)")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(Color.white.opacity(0.14))
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    // Confirm Paste
                    Button {
                        model.confirmSafePaste()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.doc.on.clipboard")
                                .font(.system(size: 10, weight: .bold))
                            Text("确认粘贴 (↩)")
                                .font(.system(size: 11.5, weight: .semibold))
                        }
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5.5)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(request.isDangerous ? Color.red.opacity(0.85) : Color.blue.opacity(0.85))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .frame(width: 440)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.50), radius: 24, y: 8)
        }
    }
}
