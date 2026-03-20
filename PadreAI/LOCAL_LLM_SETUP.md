# PadreAI - Local LLM Integration Setup

## 📦 What We've Built

PadreAI now has a complete **on-device AI** infrastructure ready for Gemma 3 4B integration:

### ✅ Completed Files:
1. **`LocalModelService.swift`** - Model download, loading, and inference management
2. **`ChatViewModel.swift`** - Conversation state and message handling
3. **`ChatMessage.swift`** - Shared message data model
4. **`ModelDownloadView.swift`** - Beautiful download UI with disclaimer
5. **`HealthChatView.swift`** - Updated chat UI connected to local model

---

## 🚀 Next Steps: Add Swift Packages

### **Step 1: Add llama.cpp (for iOS)**

1. In Xcode, go to **File → Add Package Dependencies**
2. Add this URL: `https://github.com/ggerganov/llama.cpp`
3. Select version: **Latest**
4. Add to target: **PadreAI**

**Alternative (Swift wrapper):**
- For easier Swift integration, consider: `https://github.com/ShenghaiWang/SwiftLlama`

### **Step 2: Add MLX Swift (for macOS)**

1. In Xcode, go to **File → Add Package Dependencies**
2. Add this URL: `https://github.com/ml-explore/mlx-swift`
3. Select version: **Latest**
4. Add to target: **PadreAI**

---

## 🔧 After Adding Packages

### **Update `LocalModelService.swift`:**

#### For iOS (llama.cpp):
```swift
#if os(iOS)
import llama // or SwiftLlama

private var llamaContext: LlamaContext?

func loadModel() async throws {
    guard let modelPath = modelPath?.path else {
        throw ModelError.invalidPath
    }
    
    self.llamaContext = try LlamaContext(modelPath: modelPath)
    isModelLoaded = true
}

func generateResponse(...) async throws -> String {
    guard let context = llamaContext else {
        throw ModelError.modelNotLoaded
    }
    
    return try await context.completion(for: fullPrompt)
}
#endif
```

#### For macOS (MLX):
```swift
#elseif os(macOS)
import MLX
import MLXLLM

private var mlxModel: LLMModel?

func loadModel() async throws {
    guard let modelPath = modelPath else {
        throw ModelError.invalidPath
    }
    
    let modelConfiguration = ModelConfiguration(id: modelPath.path)
    self.mlxModel = try await LLMModel.load(configuration: modelConfiguration)
    isModelLoaded = true
}

func generateResponse(...) async throws -> String {
    guard let model = mlxModel else {
        throw ModelError.modelNotLoaded
    }
    
    return try await model.generate(prompt: fullPrompt)
}
#endif
```

---

## 📥 Model Download URLs

### **iOS (GGUF Format)**
```
https://huggingface.co/bartowski/gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-Q4_K_M.gguf
```
- Size: ~3 GB
- Quantization: Q4_K_M (4-bit)
- Works with: llama.cpp

### **macOS (MLX Format)**
```
https://huggingface.co/mlx-community/gemma-3-4b-it-4bit
```
- Size: ~3 GB
- Quantization: 4-bit
- Works with: MLX Swift

**Note:** The current download implementation is simplified. For production:
- Add retry logic
- Add checksum verification
- Handle partial downloads
- For MLX (macOS), download multiple model files (config, weights, tokenizer)

---

## 🎯 How It Works

### **User Flow:**

1. **First Launch:**
   - App opens → `HealthChatView` appears
   - Checks if model is downloaded → Not found
   - Shows `ModelDownloadView` with disclaimer

2. **Download Flow:**
   - User reads disclaimer → Accepts
   - Sees download screen with model info
   - Taps "Download Model (3 GB)"
   - Progress bar shows download status
   - Model saves to Documents directory

3. **Auto-Load:**
   - After download completes, model auto-loads into memory
   - Sheet dismisses, returns to chat

4. **Chat:**
   - User types message → Sends to local model
   - `ChatViewModel` builds prompt with system prompt + history
   - `LocalModelService` runs inference
   - Response appears in chat
   - **100% offline, 100% private**

---

## 🧪 Testing Without Packages (Current State)

Right now, the code will compile and run with **placeholder responses**:

```swift
// In LocalModelService.swift - generateResponse()
let response = "Esta es una respuesta de ejemplo. Una vez que instalemos llama.cpp, aquí verás respuestas reales del modelo Gemma 3 4B. 🚧"
```

**This lets you test:**
- ✅ Download UI flow
- ✅ Progress tracking
- ✅ Chat interface
- ✅ Message history
- ✅ Bilingual switching
- ⏳ Actual AI responses (after package integration)

---

## 🎨 Features Included

### **Model Download View:**
- ✅ Medical disclaimer (English + Spanish)
- ✅ Feature list with icons
- ✅ Privacy badges (offline, no fees)
- ✅ Model info card (size, languages)
- ✅ Download progress bar
- ✅ Cancel download option

### **Chat Interface:**
- ✅ Status banner (shows if model not downloaded)
- ✅ Message bubbles (user vs AI)
- ✅ Thinking indicator while generating
- ✅ Auto-scroll to latest message
- ✅ Disabled input while generating
- ✅ Menu: New conversation, Unload model

### **System Prompt (Mexican Spanish):**
```
Eres PadreAI, un asistente de salud bilingüe para familias hispanas.
Hablas español mexicano (no castellano) de manera natural y clara.

REGLAS IMPORTANTES:
- Nunca diagnostiques enfermedades
- Usa lenguaje simple y claro
- Respeta los remedios caseros pero sabe cuándo recomendar al doctor
- Maneja Spanglish y code-switching
- Sé cálido, empático y respetuoso
```

---

## 📱 Platform-Specific Optimizations

### **iOS:**
- Uses llama.cpp (optimized for mobile)
- Q4_K_M quantization (smaller, faster)
- Works on iPhone 15 Pro+ recommended
- Memory management for limited RAM

### **macOS:**
- Uses MLX (optimized for Apple Silicon)
- 4-bit quantization
- Better performance on M1+
- Can handle larger context windows

---

## 🔜 What to Build Next

After adding the packages and enabling real inference:

1. **Streaming Responses** - Show tokens as they're generated
2. **Context Management** - Truncate old messages to save memory
3. **Temperature Control** - Let users adjust creativity
4. **Preset Prompts** - Quick health questions
5. **Export Conversations** - Save for doctor visits
6. **Voice Input** - Accessibility for abuelos
7. **Offline OCR** - Prescription label scanning (Vision framework)

---

## 🎯 Why This Architecture Wins

| Feature | PadreAI | Cloud AI Apps |
|---------|---------|---------------|
| **Privacy** | 100% on-device | ❌ Data sent to servers |
| **Cost** | $0 forever | 💰 $20-50/month |
| **Offline** | ✅ Works anywhere | ❌ Needs internet |
| **Latency** | Fast (local) | Slower (network) |
| **Cultural** | Mexican Spanish | ❌ Generic Spanish |
| **Trust** | HIPAA-ready | ⚠️ Privacy concerns |

---

## 💡 Pro Tips

1. **Model Size vs Performance:**
   - 3B = Fast, good for basic health Q&A
   - 7B = Slower, better reasoning (future option)

2. **Quantization:**
   - Q4_K_M = Best balance (4-bit)
   - Q8 = Higher quality, 2x larger
   - Q3 = Faster, lower quality

3. **Memory Management:**
   - Load model when chat opens
   - Unload when app backgrounds (iOS)
   - Keep loaded on macOS (more RAM)

4. **Prompt Engineering:**
   - System prompt is in Spanish to bias responses
   - Include disclaimers in system prompt
   - Use examples for remedios caseros handling

---

## 🚀 Launch Checklist

Before App Store submission:

- [ ] Add Swift packages (llama.cpp, MLX)
- [ ] Test download on real devices
- [ ] Test model loading/unloading
- [ ] Test 20+ health questions
- [ ] Verify Spanish quality (Castilian vs Mexican)
- [ ] Test Spanglish code-switching
- [ ] Add analytics (local only, no tracking)
- [ ] App Store screenshots (bilingual)
- [ ] Privacy policy (no data collection)
- [ ] TestFlight beta with Latino families

---

**You're Ready to Revolutionize Health AI for 65M+ Hispanics! 🚀**

Built with ❤️ for underserved communities.
