//
//  CurrencyPickerView.swift
//  Raedam
//
//  Created by Omar Waked on 5/15/21.
//  
//

import SwiftUI

struct CurrencyPickerView: View {
    @Binding var selectedCurrency: String
    @Environment(\.dismiss) private var dismiss
    
    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD"]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(currencies, id: \.self) { currency in
                    Button(action: {
                        selectedCurrency = currency
                        dismiss()
                    }) {
                        HStack {
                            Text(currency)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedCurrency == currency {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Currency")
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
    CurrencyPickerView(selectedCurrency: .constant("USD"))
}
