# 🎮 Mini Games - Quick Start Guide

## 🚀 Getting Started

### Step 1: Deploy Firebase Indexes
```bash
# Deploy the updated Firestore indexes
firebase deploy --only firestore:indexes
```

Wait for the deployment to complete (usually takes 2-5 minutes).

---

### Step 2: Create Your First Games (Admin)

#### A. Login as Admin
1. Run the app
2. Login with admin credentials
3. Navigate to **Admin Dashboard** (from home screen)

#### B. Create Word Match Game
1. Click **"Quản lý Mini Games"**
2. Go to **"Thêm Mới"** tab
3. Fill in:
   - **Tên Game**: "Ghép Cặp Từ Cơ Bản"
   - **Mô Tả**: "Ghép từ tiếng Anh với nghĩa tiếng Việt"
   - **Loại Game**: Select "Ghép Cặp Từ (Word Match)"
   - **Danh Mục**: "Vocabulary"
   - **Độ Khó**: Select "1" (Cơ bản)
   - **Chọn Từ Vựng**: Select at least 8 words (scroll and check boxes)
4. Click **"Tạo Mini Game"**
5. ✅ Success! Your first game is created

#### C. Create Word Scramble Game
1. Click **"Thêm Mới"** tab again
2. Fill in:
   - **Tên Game**: "Xếp Chữ Thử Thách"
   - **Mô Tả**: "Sắp xếp các chữ cái để tạo thành từ đúng"
   - **Loại Game**: Select "Xếp Chữ (Word Scramble)"
   - **Danh Mục**: "Vocabulary"
   - **Độ Khó**: Select "2" (Sơ cấp)
   - **Chọn Từ Vựng**: Select at least 8-10 words
3. Click **"Tạo Mini Game"**
4. ✅ Success!

#### D. Create Word Search Game
1. Click **"Thêm Mới"** tab again
2. Fill in:
   - **Tên Game**: "Tìm Từ Vui Vẻ"
   - **Mô Tả**: "Tìm các từ ẩn trong bảng chữ cái"
   - **Loại Game**: Select "Tìm Từ (Word Search)"
   - **Danh Mục**: "Vocabulary"
   - **Độ Khó**: Select "1" (Cơ bản)
   - **Chọn Từ Vựng**: Select exactly 8 words
3. Click **"Tạo Mini Game"**
4. ✅ Success!

---

### Step 3: Test the Games (User)

#### A. Access Mini Games
1. Logout from admin (or use another account)
2. Login as regular user
3. On **Home Screen**, scroll down to **"Tính năng mới sắp ra mắt"**
4. Find **"Mini Games"** card (pink/magenta with game icon)
5. Click on it to open **Mini Games Menu**

#### B. Play Word Match Game
1. In Mini Games Menu, find your Word Match game
2. Click the **Play button** (▶️)
3. **Game Rules**:
   - Tap cards to flip them
   - Match English words with Vietnamese meanings
   - Try to complete in minimum moves
4. Complete the game and see your score!

#### C. Play Word Scramble Game
1. Back to Mini Games Menu
2. Select your Word Scramble game
3. **Game Rules**:
   - Read the Vietnamese meaning hint
   - Tap letters to build the correct word
   - Use hints if needed (-20 points each)
   - Skip if stuck
4. Complete all 10 words and see your results!

#### D. Play Word Search Game
1. Back to Mini Games Menu
2. Select your Word Search game
3. **Game Rules**:
   - Find 8 hidden words in the grid
   - Tap cells to select
   - Words can be horizontal, vertical, or diagonal
   - Check words list to see what to find
4. Find all words and celebrate!

---

### Step 4: View Statistics (Admin)

1. Go back to **Admin Dashboard** → **"Quản lý Mini Games"**
2. Click **"Thống Kê"** tab
3. View:
   - Total games created
   - Total plays across all games
   - Average scores
   - Most popular game

---

## 🎯 Sample Game Configurations

### Easy Level (Difficulty 1)
- **Words**: 8-10 basic vocabulary words
- **Categories**: Common vocabulary, greetings, numbers
- **Recommended for**: Beginners

### Medium Level (Difficulty 2-3)
- **Words**: 10-15 intermediate words
- **Categories**: Food, animals, daily activities
- **Recommended for**: Elementary to Intermediate

### Hard Level (Difficulty 4-5)
- **Words**: 15-20 advanced words
- **Categories**: Business, academic, idioms
- **Recommended for**: Advanced learners

---

## 🔥 Pro Tips

### For Admins:
1. **Balance Difficulty**: Create games for all levels
2. **Mix Categories**: Variety keeps users engaged
3. **Update Regularly**: Add new games weekly
4. **Monitor Stats**: Use statistics to understand what works
5. **Test Games**: Always play-test before publishing

### For Users:
1. **Start Easy**: Begin with difficulty level 1
2. **Use Hints Wisely**: Save them for harder words
3. **Time Management**: Word Search has no time pressure
4. **Practice**: Replay games to improve scores
5. **Challenge Yourself**: Progress to harder levels

---

## 📊 Understanding Scoring

### Word Match Game
- **100 points** per correct match
- **Maximum**: 600 points (6 pairs)
- **Bonus**: Fewer moves = better performance

### Word Scramble Game
- **100 points** per correct word
- **-20 points** per hint used
- **Maximum**: 1000 points (10 words, no hints)

### Word Search Game
- **100 points** per word found
- **Maximum**: 800 points (8 words)
- **Bonus**: Faster completion = better rank

---

## 🐛 Troubleshooting

### Issue: "Không tìm thấy từ vựng cho game này"
**Solution**: 
- Ensure you selected at least 8 vocabulary words when creating the game
- Check that vocabulary words still exist in database

### Issue: Game not appearing in menu
**Solution**:
- Verify game `isActive` is set to `true`
- Check Firestore indexes are deployed
- Refresh the app

### Issue: Scores not saving
**Solution**:
- Check Firebase connection
- Verify user is logged in
- Check Firestore rules allow write access

### Issue: Indexes not working
**Solution**:
```bash
# Re-deploy indexes
firebase deploy --only firestore:indexes

# Check status
firebase firestore:indexes
```

---

## 🎨 Customization Ideas

### Adding More Game Types:
1. **Copy existing game screen** (e.g., `word_match_game_screen.dart`)
2. **Modify game logic** for new gameplay
3. **Update `_getGameTypeIcon()` and `_getGameTypeColor()`** in menu
4. **Add to game type constants** in models
5. **Update admin form** with new option

### Changing Colors:
- Edit color constants in each game screen
- Update `_getGameTypeColor()` in menu screen
- Modify gradient definitions

### Adding Sounds:
1. Add audio files to `assets/sounds/`
2. Use `audioplayers` package (already included)
3. Play sounds on match/correct/wrong actions

---

## ✅ Verification Checklist

Before going live, verify:

- [ ] Firebase indexes deployed successfully
- [ ] At least 3 games created (one of each type)
- [ ] All games playable without errors
- [ ] Scores saving correctly to Firebase
- [ ] Admin can edit/delete games
- [ ] Statistics showing correctly
- [ ] Mobile responsive design working
- [ ] Navigation flows smoothly
- [ ] No console errors
- [ ] User can access from home screen

---

## 🎉 You're All Set!

Your mini-games feature is now **fully operational**! Users can enjoy:
- 🎴 **Word Match** - Memory and matching
- 🔤 **Word Scramble** - Unscramble words
- 🔍 **Word Search** - Find hidden words

Start creating more games and watch your users learn English through fun gameplay! 🚀

---

## 📞 Need Help?

If you encounter any issues:
1. Check the troubleshooting section above
2. Review the main implementation document (`MINI_GAMES_IMPLEMENTATION_COMPLETE.md`)
3. Verify all files are properly saved
4. Check Firebase console for errors

Happy Gaming! 🎮✨

