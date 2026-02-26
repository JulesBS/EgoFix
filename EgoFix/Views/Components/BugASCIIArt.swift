import SwiftUI

/// ASCII art representations for each of the 7 ego bugs.
/// Small terminal-style art (5-8 lines, 20-30 chars wide).
enum BugASCIIArt {
    /// Returns the ASCII art for a given bug slug
    static func art(for slug: String) -> String {
        switch slug {
        case "need-to-be-right":
            return needToBeRight
        case "need-to-impress":
            return needToImpress
        case "need-to-be-liked":
            return needToBeLiked
        case "need-to-control":
            return needToControl
        case "need-to-compare":
            return needToCompare
        case "need-to-deflect":
            return needToDeflect
        case "need-to-narrate":
            return needToNarrate
        default:
            return unknown
        }
    }

    /// Returns the accent color for a given bug slug
    static func color(for slug: String) -> Color {
        switch slug {
        case "need-to-be-right":
            return Color(red: 1.0, green: 0.4, blue: 0.3)
        case "need-to-impress":
            return Color(red: 0.6, green: 0.4, blue: 0.8)
        case "need-to-be-liked":
            return Color(red: 0.3, green: 0.8, blue: 0.8)
        case "need-to-control":
            return Color(red: 1.0, green: 0.8, blue: 0.3)
        case "need-to-compare":
            return Color(red: 0.4, green: 0.8, blue: 0.4)
        case "need-to-deflect":
            return Color(red: 0.6, green: 0.6, blue: 0.6)
        case "need-to-narrate":
            return Color(red: 0.3, green: 0.5, blue: 0.8)
        default:
            return .gray
        }
    }

    // MARK: - Individual Bug Art

    /// Need to be right - pointing finger / exclamation
    private static let needToBeRight = """
          !
         /|\\
        / | \\
          |
         _|_
        |   |
        | ! |
        |___|
    """

    /// Need to impress - spotlight / stage
    private static let needToImpress = """
         \\|/
        --*--
         /|\\
          |
       ___O___
      /       \\
     /  STAGE  \\
    /___________\\
    """

    /// Need to be liked - mask / mirror
    private static let needToBeLiked = """
       .-----.
      /  ^ ^  \\
     |  (   )  |
      \\  ===  /
       '-----'
         |||
        /   \\
       /     \\
    """

    /// Need to control - puppet strings / grid
    private static let needToControl = """
        |  |  |
        |  |  |
       _|__|__|_
      |  CTRL   |
      +--+--+--+
      |  |  |  |
      +--+--+--+
      |__|__|__|
    """

    /// Need to compare - scale / balance
    private static let needToCompare = """
           ^
          /|\\
         / | \\
        /  |  \\
       .   |   .
      ___  |  ___
     |   | | |   |
     |_<_| | |_>_|
    """

    /// Need to deflect - shield / bouncing arrow
    private static let needToDeflect = """
        -->  \\
              \\
        .------+
       /   ||   \\
      |    ||    |
      |    ||    |
       \\   ||   /
        '------'
    """

    /// Need to narrate - speech bubble / microphone
    private static let needToNarrate = """
       .--------.
      |  blah    |
      |   blah   |
       '----.---'
            |
           _|_
          |   |
          | O |
          |___|
    """

    /// Unknown bug type fallback
    private static let unknown = """
         ???
        /   \\
       |  ?  |
        \\ ? /
         ???
    """
}

/// A view that displays ASCII art for a bug
struct BugASCIIArtView: View {
    let slug: String
    var showArt: Bool = true

    var body: some View {
        if showArt {
            Text(BugASCIIArt.art(for: slug))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(BugASCIIArt.color(for: slug).opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(0)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 32) {
            ForEach([
                "need-to-be-right",
                "need-to-impress",
                "need-to-be-liked",
                "need-to-control",
                "need-to-compare",
                "need-to-deflect",
                "need-to-narrate"
            ], id: \.self) { slug in
                VStack(spacing: 8) {
                    Text(slug)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                    BugASCIIArtView(slug: slug)
                }
            }
        }
        .padding()
    }
    .background(Color.black)
}
