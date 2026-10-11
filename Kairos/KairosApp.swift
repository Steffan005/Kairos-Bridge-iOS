// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Steffan Douglas Haskins
import SwiftUI

@main
struct KairosApp: App {
    @StateObject private var model = KairosModel()
    var body: some Scene {
        WindowGroup { KairosRoot().environmentObject(model).task { await model.restore() } }
    }
}
