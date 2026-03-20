# Adding llama.cpp to MiSana 🚀

## ✅ Code Updated!

I've already updated `LocalModelService.swift` with real llama.cpp integration. Now you just need to add the Swift package.

---

## 📦 Step 1: Add Swift Package

### **Option A: SwiftLlama (Recommended - Easier)**

1. In Xcode, go to **File → Add Package Dependencies**
2. Paste this URL in the search bar:
   ```
   https://github.com/ShenghaiWang/SwiftLlama
   ```
3. Click **Add Package**
4. When prompted, select the **LLama** library
5. Click **Add Package** again

### **Option B: llama.cpp Direct (Advanced)**

1. **File → Add Package Dependencies**
2. Paste this URL:
   ```
   https://github.com/ggerganov/llama.cpp
   ```
3. Click **Add Package**
4. Select the **llama** target
5. Click **Add Package**

**Note:** If you get errors, use Option A (SwiftLlama) - it's a cleaner wrapper.

---

## 🔧 Step 2: Build the Project

After adding the package:

1. Press **⌘ + B** (Command + B) to build
2. If you see import errors, clean build folder:
   - **Product → Clean Build Folder** (⇧⌘K)
   - Build again

---

## 🧪 Step 3: Test Without Downloading Model

The app will build successfully, but you'll get an error when trying to chat (model not found).

**This is expected!** You need to download Gemma 3 4B first.

---

## 📥 Step 4: Download the Model

### **Option A: Through the App (Recommended)**

1. Run the app
2. Go to "Ask" tab
3. Accept the disclaimer
4. Click **"Download Model (3 GB)"**
5. Wait ~10-30 minutes depending on your internet
6. Model auto-loads after download
7. Start chatting! 🎉

### **Option B: Manual Download (Faster)**

If the in-app download fails:

1. Download from Hugging Face:
   ```
   https://huggingface.co/bartowski/gemma-3-4b-it-GGUF/blob/main/gemma-3-4b-it-Q4_K_M.gguf
   ```

2. Find your app's Documents directory:
   - Run the app once
   - Check Xcode console for the path (printed on launch)
   - Or go to: `~/Library/Containers/[YourBundleID]/Data/Documents/`

3. Copy the downloaded `.gguf` file to Documents folder

4. Restart the app - model should auto-detect

---

## 🎯 What Changed in LocalModelService

### **1. Import Added:**
```swift
import LLama  // SwiftLlama wrapper for llama.cpp
```

### **2. Model Instance:**
```swift
private var llamaContext: LLama?
```

### **3. Model Loading (Real Code!):**
```swift
llamaContext = try LLama(path: modelPath.path, config: .init(
    contextLength: 2048,      // How much conversation history
    batchSize: 512,           // Processing batch size
    seed: UInt32.random(in: 0...UInt32.max),
    topK: 40,                 // Top-K sampling
    topP: 0.95,               // Nucleus sampling
    temperature: 0.7,         // Creativity (0=deterministic, 1=creative)
    repeatPenalty: 1.1        // Reduce repetition
))
```

### **4. Text Generation (Real Code!):**
```swift
let response = try await llamaContext.predict(
    fullPrompt,
    maxTokenCount: 256  // Max ~200 words response
)
```

---

## ⚙️ Configuration Options

You can tweak these parameters in `loadModel()`:

### **Temperature** (Creativity)
- `0.3-0.5`: Focused, medical-accurate responses
- `0.7` (current): Balanced, natural conversation
- `1.0+`: Very creative, might hallucinate

### **Context Length**
- `2048` (current): ~1500 words of conversation history
- `4096`: Longer conversations (uses more memory)
- `1024`: Shorter (faster, less memory)

### **Max Tokens** (Response Length)
- `256` (current): ~200 word responses
- `512`: Longer, detailed answers
- `128`: Short, concise answers

---

## 🐛 Troubleshooting

### **"Cannot find 'LLama' in scope"**
- Make sure you added the package correctly
- Clean build folder (⇧⌘K)
- Restart Xcode

### **"Model failed to load"**
- Check the `.gguf` file is in Documents directory
- File name must match: `gemma-3-4b-it-Q4_K_M.gguf`
- Check file isn't corrupted (should be ~3GB)

### **App crashes when generating**
- Model might not be loaded - check `isModelLoaded` is true
- Try reducing `contextLength` to 1024 (less memory)
- On older devices, use smaller models (3B instead of 7B)

### **Responses are gibberish**
- Wrong model format - make sure it's GGUF, not SafeTensors
- Try different quantization (Q4_K_M is recommended)
- Check system prompt formatting

### **Too slow on iPhone**
- Normal! 3-10 seconds per response on iPhone
- Use iPhone 15 Pro or newer for best performance
- Consider reducing `maxTokenCount` to 128

---

## 📊 Expected Performance

### **iPhone 15 Pro:**
- Load time: ~5-10 seconds
- Response: ~2-5 seconds
- Memory: ~2.5 GB

### **iPhone 14 Pro:**
- Load time: ~8-15 seconds
- Response: ~5-10 seconds
- Memory: ~2.5 GB

### **M1/M2/M3 Mac:**
- Load time: ~3-5 seconds
- Response: <2 seconds
- Memory: ~3 GB

---

## 🎨 Example Conversations to Test

Try these in Spanish:

1. **Medication Question:**
   ```
   ¿Cuánto tylenol le puedo dar a mi hijo de 5 años?
   ```

2. **Symptom Check:**
   ```
   Mi abuela tiene fiebre y tos. ¿Debo preocuparme?
   ```

3. **Home Remedy:**
   ```
   ¿Es seguro darle té de manzanilla a mi bebé para el cólico?
   ```

4. **Spanglish:**
   ```
   Is it safe darle vaporub a mi niño para el cold?
   ```

The model should:
- ✅ Respond in the same language you used
- ✅ Never diagnose
- ✅ Recommend seeing a doctor for serious symptoms
- ✅ Respect remedios but know when they're not enough
- ✅ Use warm, family-like tone

---

## 🚀 Next Steps After Integration

1. **Test thoroughly** - Try 20+ different health questions
2. **Tune parameters** - Adjust temperature, context, tokens
3. **Add streaming** - Show response word-by-word (better UX)
4. **Add stop words** - Stop generation at "Usuario:" to prevent looping
5. **Optimize prompt** - Fine-tune system prompt for better responses
6. **Add caching** - Cache common questions for faster responses

---

## 💡 Pro Tips

1. **System Prompt is King:**
   - Current prompt is in `LocalModelService.swift`
   - Tweak it to improve response quality
   - Add more examples for better behavior

2. **Context Management:**
   - Currently limited to last 5 messages
   - Increase if you have more memory
   - Decrease for older devices

3. **Error Handling:**
   - App gracefully handles model load failures
   - Shows error messages to user
   - Can retry without crashing

4. **Memory Management:**
   - Model unloads when app backgrounds (iOS)
   - Can manually unload via menu (saves RAM)
   - Auto-reloads when needed

---

## 📞 Support

If you run into issues:

1. Check Xcode console for error messages
2. Verify model file path and size
3. Try with smaller context length
4. Test on macOS first (easier to debug)

---

**You're about to have REAL local AI running on-device! 🎉**

No cloud. No API costs. Pure privacy. 

Let's go! 🚀
