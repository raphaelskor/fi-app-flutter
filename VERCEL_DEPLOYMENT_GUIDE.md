# 🚀 Deploy Flutter Web ke Vercel

## Problem: Website Putih/Blank Setelah Deploy

Flutter web apps sering muncul blank/putih di Vercel karena:
1. ❌ Routing issue - SPA routing tidak dikonfigurasi
2. ❌ CORS headers tidak ada (untuk CanvasKit)
3. ❌ Base href salah
4. ❌ Loading indicator tidak ada

## ✅ Solusi Lengkap

### 1. File yang Diperlukan

#### **vercel.json** (root project)
```json
{
  "version": 2,
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web",
  "routes": [
    {
      "handle": "filesystem"
    },
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Cross-Origin-Embedder-Policy",
          "value": "require-corp"
        },
        {
          "key": "Cross-Origin-Opener-Policy",
          "value": "same-origin"
        }
      ]
    }
  ]
}
```

**Penjelasan:**
- `routes`: SPA routing - semua path diarahkan ke index.html
- `headers`: CORS headers untuk CanvasKit renderer
- `outputDirectory`: Folder output Flutter web build

#### **.vercelignore** (root project)
File ini sudah dibuat - untuk exclude file yang tidak perlu di-upload.

### 2. Build Flutter Web

```bash
# Clean build artifacts
flutter clean

# Build untuk production
flutter build web --release
```

### 3. Deploy Options

#### Option A: Deploy via Vercel CLI (Recommended)

```bash
# Install Vercel CLI (one time)
npm i -g vercel

# Login to Vercel
vercel login

# Deploy
cd c:\Project\fiapp
vercel

# Production deploy
vercel --prod
```

#### Option B: Deploy via Vercel Web Dashboard

1. **Login ke Vercel**: https://vercel.com
2. **Import Project**:
   - Click "Add New Project"
   - Import from Git repository (GitHub/GitLab/Bitbucket)
   - ATAU Upload folder `c:\Project\fiapp`

3. **Configure Project**:
   ```
   Framework Preset: Other
   Root Directory: ./
   Build Command: flutter build web --release
   Output Directory: build/web
   ```

4. **Deploy**: Click "Deploy"

#### Option C: Manual Deploy (Upload Folder)

Jika tidak pakai Git/CLI, upload HANYA folder **`build/web`**:

1. Login ke Vercel dashboard
2. Drag & drop folder `c:\Project\fiapp\build\web` ke Vercel
3. Vercel akan auto-detect sebagai static site

⚠️ **PENTING**: 
- Jika upload manual, copy file `vercel.json` ke dalam folder `build/web` dulu
- Atau deploy dari root project, bukan dari folder build/web

### 4. Verifikasi Deploy

Setelah deploy sukses:

✅ **Check halaman loading:**
- Harus muncul loading spinner dengan text "Loading..."
- Loading indicator hilang setelah Flutter app fully loaded

✅ **Check console browser:**
- Buka DevTools (F12)
- Pastikan tidak ada error CORS atau 404
- Check Network tab - semua asset harus load (200 status)

✅ **Check routing:**
- Refresh page - harus tetap di halaman yang sama
- Deep links harus work

## 🔧 Troubleshooting

### Problem: Masih Blank/Putih

**Solution 1: Clear Browser Cache**
```
Ctrl + Shift + R (hard refresh)
Atau Ctrl + Shift + Delete (clear cache)
```

**Solution 2: Check Browser Console**
```
F12 → Console tab
Lihat error apa yang muncul
```

**Solution 3: Test Locally**
```bash
# Serve locally untuk test
cd c:\Project\fiapp\build\web
python -m http.server 8000

# Buka browser: http://localhost:8000
```

**Solution 4: Rebuild dengan base-href**
```bash
flutter build web --release --base-href /
```

### Problem: Assets Tidak Load (404)

**Check vercel.json:**
- Pastikan `outputDirectory: "build/web"` benar
- Pastikan file vercel.json ada di root project

**Check index.html:**
- Base href harus `<base href="/">`
- Bukan `<base href="/fiapp/">` atau lainnya

### Problem: CORS Error di Console

**Add CORS headers di vercel.json** (sudah ada):
```json
"headers": [
  {
    "source": "/(.*)",
    "headers": [
      {"key": "Cross-Origin-Embedder-Policy", "value": "require-corp"},
      {"key": "Cross-Origin-Opener-Policy", "value": "same-origin"}
    ]
  }
]
```

### Problem: Loading Stuck Forever

**Check flutter_bootstrap.js:**
```bash
# Pastikan file ada di build/web/
ls c:\Project\fiapp\build\web\flutter_bootstrap.js
```

**Rebuild jika perlu:**
```bash
flutter clean
flutter build web --release
```

## 📦 File Structure Untuk Deploy

```
fiapp/
├── build/
│   └── web/              ← Ini yang di-deploy
│       ├── assets/
│       ├── canvaskit/
│       ├── icons/
│       ├── index.html    ← Updated dengan loading indicator
│       ├── main.dart.js
│       ├── flutter_bootstrap.js
│       └── manifest.json
├── vercel.json           ← Konfigurasi Vercel
└── .vercelignore         ← File yang diabaikan
```

## 🌐 Environment Setup

### Production URL
Setelah deploy, Vercel akan kasih URL:
```
https://your-project.vercel.app
```

### Custom Domain (Optional)
1. Go to Project Settings → Domains
2. Add custom domain
3. Update DNS records sesuai instruksi Vercel

## ⚡ Performance Tips

1. **Enable Gzip Compression** (auto-enabled di Vercel)
2. **Use CDN** (Vercel Edge Network - auto)
3. **Lazy Loading**: Flutter web sudah optimized
4. **Tree Shaking**: Build dengan `--release` flag (auto)

## 🎯 Final Checklist

Sebelum deploy, pastikan:
- [x] `flutter build web --release` berhasil
- [x] File `vercel.json` ada di root project
- [x] File `.vercelignore` ada di root project
- [x] `index.html` updated dengan loading indicator
- [x] Test locally dulu: `python -m http.server 8000`
- [x] Browser DevTools tidak ada error
- [x] Assets load dengan benar

## 🚨 Known Issues

### Issue: Flutter Web Not Mobile-Friendly
Flutter web build ini untuk **desktop web**, bukan mobile web:
- Location services mungkin tidak work di browser
- Camera/Gallery permission berbeda
- Touch gestures mungkin tidak optimal

**Recommendation**: 
- Deploy Android APK/iOS IPA untuk mobile users
- Web version hanya untuk demo/testing

### Issue: Large Initial Load
Flutter web bundle bisa besar (2-10 MB):
- First load bisa lama
- Gunakan loading indicator (sudah ada)
- Consider PWA untuk caching

### Issue: Backend API CORS
Jika API skorcard.app block CORS dari Vercel:
- Contact backend team untuk whitelist Vercel domain
- Atau deploy backend proxy di Vercel

## 📚 Resources

- [Vercel Flutter Guide](https://vercel.com/guides/deploying-flutter-with-vercel)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Vercel Configuration](https://vercel.com/docs/configuration)

---

**Summary**: 
1. Buat `vercel.json` dengan routing config
2. Build: `flutter build web --release`
3. Deploy: `vercel` atau upload via dashboard
4. Verify: Check loading, console, assets

Sekarang website harusnya tidak blank lagi! 🎉
