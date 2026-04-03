//
//  SupabaseClient.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Supabase
import Foundation

enum SupabaseConfig {
    // TODO: Replace with real values before release
    static let url = URL(string: "https://placeholder.supabase.co")!
    static let anonKey = "placeholder-anon-key"
}

let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey
)
