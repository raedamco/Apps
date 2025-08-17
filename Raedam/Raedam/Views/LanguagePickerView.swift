//
//  LanguagePickerView.swift
//  Raedam
//
//  Created by Omar Waked on 5/15/21.
//  
//

import SwiftUI

struct LanguagePickerView: View {
    @Binding var selectedLanguage: String
    @Environment(\.dismiss) private var dismiss
    
    private let languages = ["English", "Spanish", "French", "German", "Chinese"]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(languages, id: \.self) { language in
                    Button(action: {
                        selectedLanguage = language
                        dismiss()
                    }) {
                        HStack {
                            Text(language)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LanguagePickerView(selectedLanguage: .constant("English"))
}
