import Foundation

/// Frame data for all 7 bug soul animations at 3 intensity levels.
/// Each frame set contains 4-8 frames of identical dimensions (padded with spaces).
/// Used by `BugSoulView` for timer-driven ASCII animation.
enum BugSoulFrames {

    /// Returns frames for a given bug slug and intensity
    static func frames(for slug: String, intensity: BugIntensity) -> [String] {
        switch slug {
        case "need-to-be-right": return correctorFrames(intensity)
        case "need-to-impress": return performerFrames(intensity)
        case "need-to-be-liked": return chameleonFrames(intensity)
        case "need-to-control": return controllerFrames(intensity)
        case "need-to-compare": return scorekeeperFrames(intensity)
        case "need-to-deflect": return deflectorFrames(intensity)
        case "need-to-narrate": return narratorFrames(intensity)
        default: return unknownFrames()
        }
    }

    // MARK: - The Corrector (need-to-be-right)
    // Exclamation mark / pointing finger. Pulses, jabs, glitches.

    private static func correctorFrames(_ intensity: BugIntensity) -> [String] {
        switch intensity {
        case .quiet:
            // 4 frames: gentle pulse of exclamation mark
            return [
                """
                      .      \n\
                     /|\\     \n\
                    / | \\    \n\
                      |      \n\
                     _!_     \n\
                    |   |    \n\
                    |___|
                """,
                """
                      .      \n\
                     /|\\     \n\
                    / | \\    \n\
                      |      \n\
                     _!_     \n\
                    | . |    \n\
                    |___|
                """,
                """
                      .      \n\
                     /|\\     \n\
                    / | \\    \n\
                      |      \n\
                     _._     \n\
                    |   |    \n\
                    |___|
                """,
                """
                      .      \n\
                     /|\\     \n\
                    / | \\    \n\
                      |      \n\
                     _!_     \n\
                    | . |    \n\
                    |___|
                """,
            ]
        case .present:
            // 6 frames: exclamation wags, finger points more
            return [
                """
                      !      \n\
                     /|\\     \n\
                    / | \\    \n\
                      |      \n\
                     _!_     \n\
                    | ! |    \n\
                    |___|
                """,
                """
                     !       \n\
                     /|\\     \n\
                    / | \\    \n\
                     /       \n\
                     _!_     \n\
                    | ! |    \n\
                    |___|
                """,
                """
                      !      \n\
                     /|\\     \n\
                    / | \\    \n\
                      |      \n\
                     _!_     \n\
                    |!! |    \n\
                    |___|
                """,
                """
                       !     \n\
                     /|\\     \n\
                    / | \\    \n\
                       \\     \n\
                     _!_     \n\
                    | !!|    \n\
                    |___|
                """,
                """
                      !      \n\
                     /|\\     \n\
                    / | \\    \n\
                      |      \n\
                     _!_     \n\
                    | ! |    \n\
                    |___|
                """,
                """
                     !       \n\
                     /|\\     \n\
                    / | \\    \n\
                     /       \n\
                     _!_     \n\
                    |!  |    \n\
                    |___|
                """,
            ]
        case .loud:
            // 8 frames: doubled !!, jabbing, glitch scatter
            return [
                """
                     !!      \n\
                     /|\\     \n\
                    / | \\    \n\
                      |      \n\
                     _!_     \n\
                    |!! |    \n\
                    |___|
                """,
                """
                    ! !!     \n\
                     /|\\     \n\
                    /!| \\    \n\
                     /       \n\
                     _!_     \n\
                    |!!!|    \n\
                    |___|
                """,
                """
                     !!      \n\
                     /|!     \n\
                    / |  \\   \n\
                      |!     \n\
                     _!_     \n\
                    |! !|    \n\
                    |_!_|
                """,
                """
                    !!!      \n\
                     /|\\     \n\
                    /!| \\    \n\
                     !|      \n\
                     _!_     \n\
                    |!! |    \n\
                    |___|
                """,
                """
                     !!      \n\
                     /|\\     \n\
                    / |! \\   \n\
                      |      \n\
                     _!!     \n\
                    |!!!|    \n\
                    |_!_|
                """,
                """
                    ! !      \n\
                     /|\\!    \n\
                    / | \\    \n\
                     /!      \n\
                     _!_     \n\
                    |! !|    \n\
                    |___|
                """,
                """
                     !!!     \n\
                     /|\\     \n\
                    /!|!\\    \n\
                      |      \n\
                     _!_     \n\
                    |!!!|    \n\
                    |_!_|
                """,
                """
                    !! !     \n\
                     /|\\     \n\
                    / |  \\   \n\
                     !|!     \n\
                     _!_     \n\
                    |!! |    \n\
                    |___|
                """,
            ]
        }
    }

    // MARK: - The Performer (need-to-impress)
    // Spotlight / figure on stage. Poses, sweeps, strobes.

    private static func performerFrames(_ intensity: BugIntensity) -> [String] {
        switch intensity {
        case .quiet:
            // 4 frames: spotlight barely visible, figure still
            return [
                """
                     \\|/     \n\
                    --*--    \n\
                      |      \n\
                      O      \n\
                     /|\\     \n\
                     / \\     \n\
                   _______
                """,
                """
                     \\|/     \n\
                    --*--    \n\
                      |      \n\
                      O      \n\
                     /|\\     \n\
                     / \\     \n\
                   _______
                """,
                """
                      |      \n\
                    --*--    \n\
                      |      \n\
                      O      \n\
                     /|\\     \n\
                     / \\     \n\
                   _______
                """,
                """
                     \\|/     \n\
                    --*--    \n\
                      |      \n\
                      O      \n\
                     /|\\     \n\
                     / \\     \n\
                   _______
                """,
            ]
        case .present:
            // 6 frames: figure posing, spotlight sweeping
            return [
                """
                    \\ | /    \n\
                    --*--    \n\
                      |      \n\
                      O      \n\
                     /|\\     \n\
                     / \\     \n\
                   _______
                """,
                """
                   \\  |      \n\
                    --*--    \n\
                     /       \n\
                      O      \n\
                     /|      \n\
                     / \\     \n\
                   _______
                """,
                """
                    \\ | /    \n\
                    --*--    \n\
                      |      \n\
                      O/     \n\
                     /|      \n\
                     / \\     \n\
                   _______
                """,
                """
                      |  /   \n\
                    --*--    \n\
                       \\     \n\
                      O      \n\
                      |\\     \n\
                     / \\     \n\
                   _______
                """,
                """
                    \\ | /    \n\
                    --*--    \n\
                      |      \n\
                     \\O      \n\
                      |\\     \n\
                     / \\     \n\
                   _______
                """,
                """
                    \\ | /    \n\
                    --*--    \n\
                      |      \n\
                      O      \n\
                     /|\\     \n\
                     / \\     \n\
                   _______
                """,
            ]
        case .loud:
            // 8 frames: frantic posing, strobing, LOOK fragments
            return [
                """
                   \\\\|//     \n\
                    -*!*-    \n\
                      |      \n\
                      O/     \n\
                     /|      \n\
                     / \\     \n\
                   _LOOK__
                """,
                """
                    LOOK!    \n\
                    --*--    \n\
                     /       \n\
                    \\O/      \n\
                      |      \n\
                     / \\     \n\
                   _______
                """,
                """
                   \\\\|//     \n\
                    -*!*-    \n\
                      |      \n\
                     \\O/     \n\
                      |      \n\
                     | |     \n\
                   __SEE__
                """,
                """
                    *   *    \n\
                    --*--    \n\
                      |!     \n\
                      O--    \n\
                     /|      \n\
                     / \\     \n\
                   _LOOK__
                """,
                """
                   \\\\|//     \n\
                    !*!*!    \n\
                      |      \n\
                    --O--    \n\
                      |      \n\
                     / \\     \n\
                   _______
                """,
                """
                    LOOK     \n\
                    -*!*-    \n\
                     /       \n\
                      O/     \n\
                     /|      \n\
                     | |     \n\
                   __SEE__
                """,
                """
                   \\\\|//     \n\
                    --*--    \n\
                      |!     \n\
                     \\O/     \n\
                      |      \n\
                     / \\     \n\
                   _LOOK__
                """,
                """
                    *!*!*    \n\
                    -*!*-    \n\
                      |      \n\
                      O--    \n\
                      |\\     \n\
                     / \\     \n\
                   _______
                """,
            ]
        }
    }

    // MARK: - The Chameleon (need-to-be-liked)
    // Face/mask shifting expressions. Fragments at loud.

    private static func chameleonFrames(_ intensity: BugIntensity) -> [String] {
        switch intensity {
        case .quiet:
            // 4 frames: face mostly stable, subtle shift
            return [
                """
                   .------.  \n\
                  /  o  o  \\ \n\
                 |    --    |\n\
                  \\  ====  / \n\
                   '------'  \n\
                     ||||    \n\
                    /    \\
                """,
                """
                   .------.  \n\
                  /  o  o  \\ \n\
                 |    --    |\n\
                  \\  ====  / \n\
                   '------'  \n\
                     ||||    \n\
                    /    \\
                """,
                """
                   .------.  \n\
                  /  o  o  \\ \n\
                 |    --    |\n\
                  \\  .==.  / \n\
                   '------'  \n\
                     ||||    \n\
                    /    \\
                """,
                """
                   .------.  \n\
                  /  o  o  \\ \n\
                 |    --    |\n\
                  \\  ====  / \n\
                   '------'  \n\
                     ||||    \n\
                    /    \\
                """,
            ]
        case .present:
            // 6 frames: alternating expressions :) :| :(
            return [
                """
                   .------.  \n\
                  /  ^  ^  \\ \n\
                 |    --    |\n\
                  \\  \\__/  / \n\
                   '------'  \n\
                     ||||    \n\
                    /    \\
                """,
                """
                   .------.  \n\
                  /  o  o  \\ \n\
                 |    --    |\n\
                  \\  ====  / \n\
                   '------'  \n\
                     ||||    \n\
                    /    \\
                """,
                """
                   .------.  \n\
                  /  -  -  \\ \n\
                 |    --    |\n\
                  \\  /==\\  / \n\
                   '------'  \n\
                     ||||    \n\
                    /    \\
                """,
                """
                   .------.  \n\
                  /  o  o  \\ \n\
                 |    --    |\n\
                  \\  \\__/  / \n\
                   '------'  \n\
                     ||||    \n\
                    /    \\
                """,
                """
                   .------.  \n\
                  /  ^  ^  \\ \n\
                 |    --    |\n\
                  \\  ====  / \n\
                   '------'  \n\
                     ||||    \n\
                    /    \\
                """,
                """
                   .------.  \n\
                  /  o  o  \\ \n\
                 |    --    |\n\
                  \\  /==\\  / \n\
                   '------'  \n\
                     ||||    \n\
                    /    \\
                """,
            ]
        case .loud:
            // 8 frames: rapid morph, features misaligning, identity fragmenting
            return [
                """
                   .------.  \n\
                  /  ^  o  \\ \n\
                 |    --    |\n\
                  \\  \\__/  / \n\
                   '------'  \n\
                     |--|    \n\
                    /    \\
                """,
                """
                   .--  --.  \n\
                  /  o  -  \\ \n\
                 |   \\--    |\n\
                  \\  /==   / \n\
                   '--  --'  \n\
                     ||||    \n\
                    /    \\
                """,
                """
                   .------.  \n\
                  /  -  ^  \\ \n\
                 |    --/   |\n\
                  \\ ====\\  / \n\
                   '------'  \n\
                     |  |    \n\
                    / \\/ \\
                """,
                """
                   .- -- -.  \n\
                  /  ^  ^  \\ \n\
                 |   --     |\n\
                  \\  /\\=/  / \n\
                   '------'  \n\
                     ||||    \n\
                    /    \\
                """,
                """
                   .------.  \n\
                  / \\o  o/ \\ \n\
                 |    --    |\n\
                  \\  \\==/  / \n\
                   '--.---'  \n\
                     ||||    \n\
                    /    \\
                """,
                """
                   .--- --.  \n\
                  /  o- -o \\ \n\
                 |    /--   |\n\
                  \\  ====  / \n\
                   '------'  \n\
                     |--|    \n\
                    /    \\
                """,
                """
                   .------.  \n\
                  /  -  o  \\ \n\
                 |   --\\    |\n\
                  \\  \\__   / \n\
                   '--.---'  \n\
                     ||||    \n\
                    / \\/ \\
                """,
                """
                   .- -- -.  \n\
                  /  ^  -  \\ \n\
                 |    --    |\n\
                  \\ /==\\/  / \n\
                   '------'  \n\
                     |  |    \n\
                    /    \\
                """,
            ]
        }
    }

    // MARK: - The Controller (need-to-control)
    // Grid / control panel. Switches flip and warp.

    private static func controllerFrames(_ intensity: BugIntensity) -> [String] {
        switch intensity {
        case .quiet:
            // 4 frames: grid stable, one switch occasionally flips
            return [
                """
                   |  |  |   \n\
                   |  |  |   \n\
                  _|__|__|_  \n\
                 |  CTRL   | \n\
                 +--+--+--+ \n\
                 |ON|ON|  | \n\
                 +--+--+--+
                """,
                """
                   |  |  |   \n\
                   |  |  |   \n\
                  _|__|__|_  \n\
                 |  CTRL   | \n\
                 +--+--+--+ \n\
                 |ON|ON|  | \n\
                 +--+--+--+
                """,
                """
                   |  |  |   \n\
                   |  |  |   \n\
                  _|__|__|_  \n\
                 |  CTRL   | \n\
                 +--+--+--+ \n\
                 |ON|  |ON| \n\
                 +--+--+--+
                """,
                """
                   |  |  |   \n\
                   |  |  |   \n\
                  _|__|__|_  \n\
                 |  CTRL   | \n\
                 +--+--+--+ \n\
                 |ON|ON|  | \n\
                 +--+--+--+
                """,
            ]
        case .present:
            // 6 frames: multiple switches flipping, lines shifting
            return [
                """
                   |  |  |   \n\
                   |  |  |   \n\
                  _|__|__|_  \n\
                 |  CTRL   | \n\
                 +--+--+--+ \n\
                 |ON|ON|ON| \n\
                 +--+--+--+
                """,
                """
                   | \\|  |   \n\
                   |  |  |   \n\
                  _|__|__|_  \n\
                 |  CTRL   | \n\
                 +--+--+--+ \n\
                 |  |ON|ON| \n\
                 +--+--+--+
                """,
                """
                   |  |/ |   \n\
                   |  |  |   \n\
                  _|__|__|_  \n\
                 |  CTRL   | \n\
                 +--+--+--+ \n\
                 |ON|  |ON| \n\
                 +--+--+--+
                """,
                """
                   |  |  |   \n\
                   | \\|  |   \n\
                  _|__|__|_  \n\
                 |  CTRL   | \n\
                 +--+--+--+ \n\
                 |ON|ON|  | \n\
                 +--+--+--+
                """,
                """
                   |  |  |   \n\
                   |  |/ |   \n\
                  _|__|__|_  \n\
                 |  CTRL   | \n\
                 +--+--+--+ \n\
                 |  |ON|ON| \n\
                 +--+--+--+
                """,
                """
                   |  |  |   \n\
                   |  |  |   \n\
                  _|__|__|_  \n\
                 |  CTRL   | \n\
                 +--+--+--+ \n\
                 |ON|ON|ON| \n\
                 +--+--+--+
                """,
            ]
        case .loud:
            // 8 frames: grid warping, CTRL blinking, switches misfiring
            return [
                """
                   |  |  |   \n\
                   | \\| /|   \n\
                  _|__|__|_  \n\
                 |  CTRL   | \n\
                 +--+--+--+ \n\
                 |ON|!!|ON| \n\
                 +--+--+--+
                """,
                """
                   | \\|/ |   \n\
                   |  |  |   \n\
                  _|_/|__|_  \n\
                 | !CTRL!  | \n\
                 +--+--+--+ \n\
                 |  |ON|  | \n\
                 +--+--+--+
                """,
                """
                   |  |  |   \n\
                   |/ | \\|   \n\
                  _|__|\\__|  \n\
                 |  CTRL   | \n\
                 +--+--+--+ \n\
                 |ON|ON|!!| \n\
                 +-/+--+--+
                """,
                """
                   | /|  |   \n\
                   |  |\\ |   \n\
                  _|__|__|_  \n\
                 |!!CTRL!! | \n\
                 +--+--+--+ \n\
                 |!!|  |ON| \n\
                 +--+--+-\\+
                """,
                """
                   |  |/ |   \n\
                   | \\|  |   \n\
                  _|__|__|_  \n\
                 |  CTRL!  | \n\
                 +--+--+--+ \n\
                 |ON|!!|  | \n\
                 +--+--+--+
                """,
                """
                   |/ | /|   \n\
                   |  |  |   \n\
                  _|_\\|__|_  \n\
                 | !CTRL   | \n\
                 +--+--+--+ \n\
                 |  |ON|!!| \n\
                 +--+/-+--+
                """,
                """
                   |  |  |   \n\
                   |/ |\\ |   \n\
                  _|__|__|_  \n\
                 |!!CTRL!! | \n\
                 +--+--+--+ \n\
                 |!!|!!|ON| \n\
                 +--+--+--+
                """,
                """
                   |\\ |/ |   \n\
                   |  |  |   \n\
                  _|__|/__|  \n\
                 |  CTRL!  | \n\
                 +--+--+--+ \n\
                 |ON|  |!!| \n\
                 +--+\\-+--+
                """,
            ]
        }
    }

    // MARK: - The Scorekeeper (need-to-compare)
    // Balance scale. Tips, rocks, numbers appear.

    private static func scorekeeperFrames(_ intensity: BugIntensity) -> [String] {
        switch intensity {
        case .quiet:
            // 4 frames: scale balanced, barely moving
            return [
                """
                       ^     \n\
                      /|\\    \n\
                     / | \\   \n\
                    /  |  \\  \n\
                   .   |   . \n\
                  ___  |  ___\n\
                 |   | | |   |
                """,
                """
                       ^     \n\
                      /|\\    \n\
                     / | \\   \n\
                    /  |  \\  \n\
                   .   |   . \n\
                  ___  |  ___\n\
                 |   | | |   |
                """,
                """
                       ^     \n\
                      /|\\    \n\
                     / | \\   \n\
                    /  |  \\  \n\
                   '   |   ' \n\
                  ___  |  ___\n\
                 |   | | |   |
                """,
                """
                       ^     \n\
                      /|\\    \n\
                     / | \\   \n\
                    /  |  \\  \n\
                   .   |   . \n\
                  ___  |  ___\n\
                 |   | | |   |
                """,
            ]
        case .present:
            // 6 frames: scale tipping one direction, then the other
            return [
                """
                       ^     \n\
                      /|\\    \n\
                     / | \\   \n\
                    /  |  \\  \n\
                   .   |   . \n\
                  ___  |  ___\n\
                 |   | | |   |
                """,
                """
                       ^     \n\
                      /|\\    \n\
                     / |  \\  \n\
                    /  |   \\ \n\
                   .   |    '\n\
                  ___  |  ___\n\
                 | < | | |   |
                """,
                """
                       ^     \n\
                      /|\\    \n\
                     / |  \\  \n\
                    /  |   \\ \n\
                   .   |    '\n\
                  ___  |  ___\n\
                 | < | | | > |
                """,
                """
                       ^     \n\
                      /|\\    \n\
                     / | \\   \n\
                    /  |  \\  \n\
                   .   |   . \n\
                  ___  |  ___\n\
                 |   | | |   |
                """,
                """
                       ^     \n\
                      /|\\    \n\
                    /  | \\   \n\
                   /   |  \\  \n\
                  '    |   . \n\
                  ___  |  ___\n\
                 |   | | | > |
                """,
                """
                       ^     \n\
                      /|\\    \n\
                    /  | \\   \n\
                   /   |  \\  \n\
                  '    |   . \n\
                  ___  |  ___\n\
                 | < | | | > |
                """,
            ]
        case .loud:
            // 8 frames: violent rocking, numbers appearing
            return [
                """
                       ^     \n\
                      /|\\    \n\
                    /  |  \\  \n\
                   /   |   \\ \n\
                  '    |    '\n\
                  ___  |  ___\n\
                 | 7 | | | 3 |
                """,
                """
                       ^     \n\
                      /|\\    \n\
                     / |   \\ \n\
                    /  |    \\\n\
                   .   |    '\n\
                  ___  |  ___\n\
                 |<< | | |   |
                """,
                """
                       ^     \n\
                      /|\\    \n\
                   /   | \\   \n\
                  /    |  \\  \n\
                 '     |   . \n\
                  ___  |  ___\n\
                 |   | | |>>!|
                """,
                """
                       ^     \n\
                      /|\\    \n\
                    /  |  \\  \n\
                   /   |   \\ \n\
                  '    |    '\n\
                  ___  |  ___\n\
                 | 9 | | | 2 |
                """,
                """
                       ^     \n\
                      /|\\    \n\
                     / |   \\ \n\
                    /  |    \\\n\
                   .   |    '\n\
                  ___  |  ___\n\
                 |<<!! | |   |
                """,
                """
                       ^     \n\
                      /|\\    \n\
                   /   | \\   \n\
                  /    |  \\  \n\
                 '     |   . \n\
                  ___  |  ___\n\
                 |   | | |!!>|
                """,
                """
                       ^     \n\
                      /|\\    \n\
                    /  |  \\  \n\
                   /   |   \\ \n\
                  '    |    '\n\
                  ___  |  ___\n\
                 | 4 | | | 8 |
                """,
                """
                       ^     \n\
                      /|\\    \n\
                    /  |  \\  \n\
                   /   |   \\ \n\
                  '!   |   !'\n\
                  ___  |  ___\n\
                 |!! | | | !!|
                """,
            ]
        }
    }

    // MARK: - The Deflector (need-to-deflect)
    // Shield with arrows. Cracks under barrage.

    private static func deflectorFrames(_ intensity: BugIntensity) -> [String] {
        switch intensity {
        case .quiet:
            // 4 frames: shield static, rare deflection
            return [
                """
                          \\  \n\
                   .------+  \n\
                  /   ||   \\ \n\
                 |    ||    |\n\
                 |    ||    |\n\
                  \\   ||   / \n\
                   '------'
                """,
                """
                          \\  \n\
                   .------+  \n\
                  /   ||   \\ \n\
                 |    ||    |\n\
                 |    ||    |\n\
                  \\   ||   / \n\
                   '------'
                """,
                """
                             \n\
                   .------.  \n\
                  /   ||   \\ \n\
                 |    ||    |\n\
                 |    ||    |\n\
                  \\   ||   / \n\
                   '------'
                """,
                """
                  -->     \\  \n\
                   .------+  \n\
                  /   ||   \\ \n\
                 |    ||    |\n\
                 |    ||    |\n\
                  \\   ||   / \n\
                   '------'
                """,
            ]
        case .present:
            // 6 frames: arrows more frequent, shield shifting
            return [
                """
                  -->     \\  \n\
                   .------+  \n\
                  /   ||   \\ \n\
                 |    ||    |\n\
                 |    ||    |\n\
                  \\   ||   / \n\
                   '------'
                """,
                """
                          \\  \n\
                  -->.----+  \n\
                  /   ||   \\ \n\
                 |    ||    |\n\
                 |    ||    |\n\
                  \\   ||   / \n\
                   '------'
                """,
                """
                  -->     \\  \n\
                   .------+  \n\
                  /  >||   \\ \n\
                 |    ||    |\n\
                -->   ||    |\n\
                  \\   ||   / \n\
                   '------'
                """,
                """
                          \\  \n\
                   .------+  \n\
                  /   ||   \\ \n\
                -->   ||    |\n\
                 |    ||    |\n\
                  \\  >||   / \n\
                   '------'
                """,
                """
                  -->     \\  \n\
                   .------+  \n\
                  / > ||   \\ \n\
                 |    ||    |\n\
                 |    ||    |\n\
                  \\   ||   / \n\
                  -->'-----'
                """,
                """
                          \\  \n\
                  -->.----+  \n\
                  /   ||   \\ \n\
                 |    ||    |\n\
                -->   ||    |\n\
                  \\   ||   / \n\
                   '------'
                """,
            ]
        case .loud:
            // 8 frames: barrage of arrows, shield cracking
            return [
                """
                  -->     \\  \n\
                  -->.----+  \n\
                  / > || * \\ \n\
                -->   ||    |\n\
                 |   *||    |\n\
                  \\   ||   / \n\
                   '--*---'
                """,
                """
                  -->  >  \\  \n\
                   .--*---+  \n\
                  /   ||   \\ \n\
                -->  *||    |\n\
                -->   || *  |\n\
                  \\   ||   / \n\
                  -->'-----'
                """,
                """
                  -->     \\  \n\
                  -->.--*-+  \n\
                  / > ||   \\ \n\
                 |  * ||    |\n\
                -->   ||*   |\n\
                  \\ * ||   / \n\
                   '--*---'
                """,
                """
                  --> -->  \\  \n\
                   .*------+  \n\
                  /   ||*  \\ \n\
                -->  *||    |\n\
                 |    || *  |\n\
                  \\  *||   / \n\
                   '--*---'
                """,
                """
                  -->     \\  \n\
                  -->.--*-+  \n\
                  / > ||   \\ \n\
                -->   ||*   |\n\
                --> * ||    |\n\
                  \\   ||*  / \n\
                  -->'--*--'
                """,
                """
                  --> --> \\  \n\
                   .*-*---+  \n\
                  /  >||   \\ \n\
                -->  *||    |\n\
                 |    ||  * |\n\
                  \\ * ||   / \n\
                   '--*---'
                """,
                """
                  -->     \\  \n\
                  -->.----+  \n\
                  / >*||*  \\ \n\
                --> * ||    |\n\
                -->   ||*   |\n\
                  \\  *||   / \n\
                   '*-*---'
                """,
                """
                  --> --> \\  \n\
                  -->.*---+  \n\
                  / > || * \\ \n\
                -->  *||    |\n\
                 | *  || *  |\n\
                  \\   ||*  / \n\
                  -->'*-*--'
                """,
            ]
        }
    }

    // MARK: - The Narrator (need-to-narrate)
    // Speech bubble. Words appear, overflow, spawn.

    private static func narratorFrames(_ intensity: BugIntensity) -> [String] {
        switch intensity {
        case .quiet:
            // 4 frames: single ... blinking in speech bubble
            return [
                """
                  .--------.  \n\
                 |   ...    | \n\
                 |          | \n\
                  '----.---'  \n\
                       |      \n\
                      _|_     \n\
                     |___|
                """,
                """
                  .--------.  \n\
                 |    ..    | \n\
                 |          | \n\
                  '----.---'  \n\
                       |      \n\
                      _|_     \n\
                     |___|
                """,
                """
                  .--------.  \n\
                 |     .    | \n\
                 |          | \n\
                  '----.---'  \n\
                       |      \n\
                      _|_     \n\
                     |___|
                """,
                """
                  .--------.  \n\
                 |   ...    | \n\
                 |          | \n\
                  '----.---'  \n\
                       |      \n\
                      _|_     \n\
                     |___|
                """,
            ]
        case .present:
            // 6 frames: words fading in/out
            return [
                """
                  .--------.  \n\
                 |  blah    | \n\
                 |          | \n\
                  '----.---'  \n\
                       |      \n\
                      _|_     \n\
                     |___|
                """,
                """
                  .--------.  \n\
                 |   but    | \n\
                 |          | \n\
                  '----.---'  \n\
                       |      \n\
                      _|_     \n\
                     |___|
                """,
                """
                  .--------.  \n\
                 |  well    | \n\
                 |   ...    | \n\
                  '----.---'  \n\
                       |      \n\
                      _|_     \n\
                     |___|
                """,
                """
                  .--------.  \n\
                 | unfair   | \n\
                 |          | \n\
                  '----.---'  \n\
                       |      \n\
                      _|_     \n\
                     |___|
                """,
                """
                  .--------.  \n\
                 |   just   | \n\
                 |  saying  | \n\
                  '----.---'  \n\
                       |      \n\
                      _|_     \n\
                     |___|
                """,
                """
                  .--------.  \n\
                 |  blah    | \n\
                 |   blah   | \n\
                  '----.---'  \n\
                       |      \n\
                      _|_     \n\
                     |___|
                """,
            ]
        case .loud:
            // 8 frames: bubble overflowing, text spilling, multiple bubbles
            return [
                """
                  .--------.  \n\
                 | blah blah| \n\
                 | blah blah| \n\
                  '----.---'  \n\
                       |      \n\
                      _|_     \n\
                     |___|
                """,
                """
                  .--------.. \n\
                 | BUT  blah| \n\
                 |  blah  NO| \n\
                  '----.---'  \n\
                       |      \n\
                      _|_     \n\
                     |___|
                """,
                """
                  .--------.  \n\
                 |well BLAH | \n\
                 |unfair but| \n\
                  '--blah--'  \n\
                       |      \n\
                      _|_     \n\
                     |___|
                """,
                """
                 ..--------.  \n\
                 |BLAH blah | \n\
                 | just  WHY| \n\
                  '----.---'  \n\
                      /|      \n\
                      _|_     \n\
                     |___|
                """,
                """
                  .--------.  \n\
                 |but  UNFAIR \n\
                 | blah blah| \n\
                  '----.---'  \n\
                       |\\     \n\
                      _|_     \n\
                     |___|
                """,
                """
                  .--------.. \n\
                 |WELL  blah| \n\
                 |blah  BLAH| \n\
                  '--blah--'  \n\
                       |      \n\
                      _|_     \n\
                     |___|
                """,
                """
                 ..--------.  \n\
                 | BUT  just| \n\
                 |blah  blah| \n\
                  '----.---'  \n\
                      /|      \n\
                      _|_     \n\
                     |___|
                """,
                """
                  .--------.  \n\
                 |BLAH  BLAH| \n\
                 |WHY unfair| \n\
                  '--blah--'  \n\
                       |\\     \n\
                      _|_     \n\
                     |___|
                """,
            ]
        }
    }

    // MARK: - Unknown fallback

    private static func unknownFrames() -> [String] {
        [
            """
                 ???     \n\
                /   \\    \n\
               |  ?  |   \n\
                \\ ? /    \n\
                 ???
            """,
            """
                 ???     \n\
                /   \\    \n\
               | ??? |   \n\
                \\ ? /    \n\
                 ???
            """,
            """
                 ? ?     \n\
                /   \\    \n\
               |  ?  |   \n\
                \\ ? /    \n\
                 ? ?
            """,
            """
                 ???     \n\
                / ? \\    \n\
               |  ?  |   \n\
                \\ ? /    \n\
                 ???
            """,
        ]
    }
}
