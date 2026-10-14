import SwiftUI

public struct DiagnosticsView: View {
    @StateObject private var viewModel: DiagnosticsViewModel
    
    public init(appVM: AppViewModel) {
        _viewModel = StateObject(wrappedValue: DiagnosticsViewModel(appVM: appVM))
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header & Action Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("diag_title", comment: ""))
                        .font(.system(size: 24, weight: .bold))
                    
                    Text(NSLocalizedString("diag_desc", comment: ""))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 10) {
                    Button(action: {
                        viewModel.runHardwareTest()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                            Text(NSLocalizedString("diag_test_comm", comment: ""))
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.razerGreen)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        viewModel.exportLogs()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text(NSLocalizedString("diag_export", comment: ""))
                        }
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.razerCardHover)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        viewModel.clearLogs()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.razerCardHover)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help(NSLocalizedString("diag_clear", comment: ""))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Test Result Banner
            if let result = viewModel.testResultSummary {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hardware Self-Test Results")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.razerGreen)
                    
                    Text(result)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .padding(12)
                .background(Color.razerCard)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.razerGreen.opacity(0.4), lineWidth: 1))
                .padding(.horizontal, 24)
            }
            
            // Category Filter
            HStack {
                Text("Filter by Category:")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $viewModel.selectedCategory) {
                    ForEach(viewModel.categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .frame(width: 150)
                
                Spacer()
                
                Text("\(viewModel.filteredEvents.count) Event(s)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            
            // Events Table
            List(viewModel.filteredEvents) { event in
                HStack(spacing: 12) {
                    Text(event.timestamp, style: .time)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 65, alignment: .leading)
                    
                    Text(event.level.rawValue)
                        .font(.system(size: 9, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            event.level == .success ? Color.razerSuccess.opacity(0.2) :
                            event.level == .error ? Color.razerDanger.opacity(0.2) :
                            event.level == .warning ? Color.razerWarning.opacity(0.2) :
                            Color.secondary.opacity(0.2)
                        )
                        .foregroundColor(
                            event.level == .success ? .razerSuccess :
                            event.level == .error ? .razerDanger :
                            event.level == .warning ? .razerWarning :
                            .secondary
                        )
                        .cornerRadius(4)
                        .frame(width: 55)
                    
                    Text(event.category)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(width: 80, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.message)
                            .font(.system(size: 12))
                        
                        if let details = event.details {
                            Text(details)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 2)
            }
            .listStyle(.inset)
        }
    }
}
