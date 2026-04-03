//
//  SupabaseClient.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import Supabase
import Foundation

let supabase = SupabaseClient(
    supabaseURL: URL(string: Secrets.supabaseURL)!,
    supabaseKey: Secrets.supabaseAnonKey
)
