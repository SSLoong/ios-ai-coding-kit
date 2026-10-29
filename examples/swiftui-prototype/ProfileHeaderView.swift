import SwiftUI

// MARK: - Display Model (Prototype)

struct ProfileHeaderDisplayData: Equatable {
    var displayName: String
    var bio: String
    var avatarSystemImage: String
    var isLoading: Bool

    static let loaded = ProfileHeaderDisplayData(
        displayName: "Loong",
        bio: "iOS · SwiftUI · 用 AI 加速交付，但验证标准不能省。",
        avatarSystemImage: "person.crop.circle.fill",
        isLoading: false
    )

    static let loading = ProfileHeaderDisplayData(
        displayName: "",
        bio: "",
        avatarSystemImage: "person.crop.circle",
        isLoading: true
    )
}

// MARK: - View

struct ProfileHeaderView: View {
    let data: ProfileHeaderDisplayData
    @State private var isBioExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                avatar
                VStack(alignment: .leading, spacing: 4) {
                    if data.isLoading {
                        ProgressView()
                            .accessibilityLabel("加载中")
                    } else {
                        Text(data.displayName)
                            .font(.title2.bold())
                            .accessibilityAddTraits(.isHeader)
                        Text(data.bio)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(isBioExpanded ? nil : 2)
                    }
                }
                Spacer(minLength: 0)
            }

            if !data.isLoading {
                Button {
                    isBioExpanded.toggle()
                } label: {
                    Text(isBioExpanded ? "收起简介" : "展开简介")
                        .font(.caption)
                }
                .buttonStyle(.borderless)

                Button("编辑资料") {
                    // PROTOTYPE: wire to navigation
                    debugPrint("edit profile tapped")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("打开资料编辑")
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private var avatar: some View {
        if data.isLoading {
            Circle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 64, height: 64)
        } else {
            Image(systemName: data.avatarSystemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Previews

#Preview("Loaded") {
    ProfileHeaderView(data: .loaded)
        .padding()
}

#Preview("Loading") {
    ProfileHeaderView(data: .loading)
        .padding()
}

#Preview("Large Text") {
    ProfileHeaderView(data: .loaded)
        .padding()
        .environment(\.dynamicTypeSize, .accessibility3)
}
