import SwiftUI

// MARK: - Custom Navigation Header
/// A custom header view that replaces the unreliable system navigation bar title
struct CustomNavigationHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.serifTitle(32))
                .foregroundColor(.islamicBrown)

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .background(Color.islamicBackground)
    }
}

#Preview {
    CustomNavigationHeader(title: "Bugün")
}
