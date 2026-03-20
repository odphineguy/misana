# How to Add SwiftLlama Package 📦

## ✅ Code is Ready - Just Need to Add Package!

The `LocalModelService.swift` code is fully written with real llama.cpp integration. It's just commented out until you add the package.

---

## 🚀 Step-by-Step: Add SwiftLlama

### **1. Open Package Dependencies in Xcode**

In Xcode menu bar:
```
File → Add Package Dependencies...
```

### **2. Paste Package URL**

In the search field that appears, paste:
```
https://github.com/ShenghaiWang/SwiftLlama
```

Hit **Enter** or click the search icon.

### **3. Select Package**

- Xcode will fetch the package info
- You'll see "SwiftLlama" appear
- Dependency Rule: **Up to Next Major Version** (recommended)
- Click **Add Package**

### **4. Choose Library**

When prompted "Choose Package Products":
- ✅ Check **LLama** (that's the library we need)
- ❌ Uncheck any other options if shown
- Click **Add Package**

### **5. Wait for Installation**

- Xcode will download and integrate the package
- This may take 1-2 minutes
- You'll see progress in the top bar

---

## 🔓 Step 2: Uncomment the Code

### **In `LocalModelService.swift`:**

#### **Line 10 - Uncomment the import:**
```swift
import LLama  // SwiftLlama wrapper
```

#### **Line 40 - Uncomment the model instance:**
```swift
private var llamaContext: LLama?
```

#### **Lines 171-191 - Uncomment loadModel():**
Find this block:
```swift
// TODO: Uncomment after adding SwiftLlama package
/*
do {
    llamaContext = try LLama(path: modelPath.path, config: .init(
        contextLength: 2048,
        ...
    ))
    ...
}
*/
```

**Remove the `/*` and `*/` and the TODO comment.**

Also **DELETE** this line:
```swift
print("⚠️ Add SwiftLlama package...")
```

#### **Line 198 - Uncomment unloadModel():**
```swift
llamaContext = nil  // Remove the comment
```

#### **Lines 218-256 - Uncomment generateResponse():**
Find this block:
```swift
// TODO: Uncomment after adding SwiftLlama package
/*
guard let llamaContext = llamaContext else { ... }
do {
    let response = try await llamaContext.predict(...)
    ...
}
*/
```

**Remove the `/*` and `*/` and the TODO.**

Also **DELETE** the placeholder response (lines ~258-267).

---

## 🧪 Step 3: Build and Test

### **Build:**
Press **⌘ + B** (Command + B)

Should compile with **0 errors**! ✅

### **Run:**
Press **▶️** to run the app

### **Test:**
1. Go to "Ask" tab
2. Accept disclaimer
3. Click "Download Model" (or "Download Later" to skip for now)
4. Type a message
5. See real AI response! 🎉

---

## 🎯 What You'll Get

### **With Model Downloaded:**
```
User: ¿Es seguro el tylenol para niños?

PadreAI: El Tylenol (acetaminofén) es generalmente seguro 
para niños cuando se usa correctamente. Sin embargo, es muy 
importante seguir las dosis recomendadas según la edad y peso 
del niño...

⚠️ Recuerda: Siempre consulta con un pediatra antes de dar 
cualquier medicamento a niños pequeños.
```

### **Response Features:**
- ✅ Mexican Spanish (not Castilian)
- ✅ Never diagnoses
- ✅ Warm, family-like tone
- ✅ Respects remedios caseros
- ✅ Recommends doctor when needed
- ✅ Handles Spanglish naturally

---

## 📊 Performance Expectations

### **First Time Model Load:**
- iPhone 15 Pro: ~5-10 seconds
- M1+ Mac: ~3-5 seconds

### **Response Generation:**
- iPhone 15 Pro: ~2-5 seconds
- M1+ Mac: <2 seconds

### **Memory Usage:**
- ~2.5-3 GB while model is loaded

---

## 🐛 Troubleshooting

### **"No such module 'LLama'"**
- You haven't added the package yet
- Or you didn't select "LLama" library when adding
- Try: Product → Clean Build Folder (⇧⌘K), then rebuild

### **Package won't download**
- Check internet connection
- Try using cellular data if on Mac with hotspot
- Alternative: Use different Swift package manager

### **Build errors after uncommenting**
- Make sure you uncommented ALL the sections
- Check for matching `/*` and `*/` pairs
- Clean build folder and try again

### **Model won't load**
- Check file exists: gemma-3-4b-it-Q4_K_M.gguf
- Check file size: should be ~3GB
- Check path printed in console

---

## 🎨 Quick Test Prompts

Try these after setup:

**Spanish:**
```
¿Cuánto tylenol le doy a mi hijo de 5 años?
Mi abuela tiene fiebre alta, ¿qué hago?
¿El té de manzanilla es bueno para el cólico?
```

**Spanglish:**
```
Is it safe darle vaporub para el cold?
Mi baby tiene fever, what should I do?
```

**English:**
```
Is chamomile tea safe for babies?
When should I worry about a fever?
```

The AI adapts to whatever language you use! 🌎

---

## ✅ Success Checklist

Before claiming victory:

- [ ] Package added in Xcode
- [ ] All code uncommented in LocalModelService.swift
- [ ] App builds with 0 errors
- [ ] Model downloads successfully (or manual copy works)
- [ ] Chat responds with real AI (not placeholder)
- [ ] Spanish responses are natural Mexican Spanish
- [ ] AI never diagnoses, always recommends doctor
- [ ] Handles Spanglish smoothly

---

**Ready? Let's add that package and activate the AI! 🚀**

File → Add Package Dependencies → https://github.com/ShenghaiWang/SwiftLlama

Then uncomment the code and you're LIVE! 💪🏽
