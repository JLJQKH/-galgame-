import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects
import QtQuick.Layouts
import QtCharts
import QtMultimedia
import galgame

// galgame 游玩记录 — 主界面
Window {
    width: 960; height: 540
    minimumWidth: 720; minimumHeight: 405
    visible: true; title: "🎮 " + tt("appTitle"); color: cBg
    flags: Qt.FramelessWindowHint | Qt.Window  // 无边框窗口（C++ 侧处理边缘缩放）
    // 主背景容器：纯色背景填充 + 所有背景图层统一在此内部声明（方案B 统一 bgRect 内部结构）
    Rectangle {
        id: bgRect; anchors.fill: parent; color: cBg

        // ===== 背景图层（视频）— Qt 6 官方示例结构：VideoOutput 直接在父 Rectangle 内部声明 =====
        VideoOutput {
            id: bgVideo
            anchors.fill: parent
            visible: root.bgImagePath.length > 0 && isVideoFile(root.bgImagePath)
            fillMode: VideoOutput.PreserveAspectCrop
        }

        // ===== 背景图层（静态图片）— 分层结构：外层 Item 管 opacity，内层 Image 管 layer.blur =====
        // 解决 opacity + layer.effect 在同一 Item 上冲突导致图片消失的问题（Qt 6 layer 纹理合成顺序问题）
        // layer.enabled 恒等于 visible 避免模糊值变化时 FBO 销毁重建导致闪烁
        // MultiEffect.blurEnabled 控制 blur=0 时禁用模糊运算但保持 layer 纹理不销毁
        Item {
            id: bgImageWrap
            anchors.fill: parent
            opacity: root.bgOpacity
            visible: root.bgImagePath.length > 0 && !root.bgImagePath.toLowerCase().endsWith(".gif") && !isVideoFile(root.bgImagePath)
            Image {
                id: bgImage; anchors.fill: parent
                source: root.bgImagePath.length > 0 ? "file:///" + root.bgImagePath.replace(/\\/g, "/") : ""
                fillMode: Image.PreserveAspectCrop
                layer.enabled: bgImageWrap.visible
                layer.effect: MultiEffect { blurEnabled: root.bgBlur > 0; blur: root.bgBlur; blurMax: 64 }
            }
        }

        // ===== 背景图层（GIF 动画）— 同样分层结构 =====
        Item {
            id: bgGifWrap
            anchors.fill: parent
            opacity: root.bgOpacity
            visible: root.bgImagePath.length > 0 && root.bgImagePath.toLowerCase().endsWith(".gif")
            AnimatedImage {
                id: bgGif; anchors.fill: parent
                source: root.bgImagePath.toLowerCase().endsWith(".gif") ? "file:///" + root.bgImagePath.replace(/\\/g, "/") : ""
                fillMode: Image.PreserveAspectCrop
                layer.enabled: bgGifWrap.visible
                layer.effect: MultiEffect { blurEnabled: root.bgBlur > 0; blur: root.bgBlur; blurMax: 64 }
            }
        }
    }
    id: root
    property bool isDark: false
    property string lastTheme: "blue"   // 进入黑夜模式前的主题，退出时恢复
    property string preCustomTheme: "blue"   // 进入自定义模式前的系统主题，退出自定义时恢复
    property int totalCount: 0; property int todoCount: 0
    property int playingCount: 0; property int doneCount: 0
    property string statusFilter: ""
    property string currentLang: "zh_CN"
    property bool clockVisible: true
    property string sortBy: "date"

    function reloadList() { gameListModel.refresh(searchField.text, root.statusFilter, root.sortBy); }

    readonly property var tr: ({
        zh_CN: {
            appTitle:"galgame 游玩记录", add:"➕ 添加", stats:"📊 统计",
            exportBtn:"⬆ 导出", importBtn:"⬇ 导入",
            search:"🔍 搜索游戏名称...", addTitle:"添加游戏",
            name:"游戏名称（如：CLANNAD）", type:"TAG，空格分隔（如：校园 恋爱）",
            rating:"评分 0-10（如：9.3）", selectCover:"选择封面",
            notes:"评价/感想...", save:"保存",
            totalGames:"总游戏", avgScore:"平均分", todo:"待玩",
            playing:"进行中", done:"已完成", edit:"编辑", del:"删除",
            noCover:"无图", editTitle:"编辑游戏", deleteTitle:"删除游戏",
            statsTitle:"数据统计", saveModify:"保存修改",
            deleteConfirm:"确定删除「%1」吗？\n此操作不可撤销。",
            warnName:"请填写游戏名称", warnType:"请选择 TAG（如：校园）",
            warnRating:"评分请填 0–10 的数字",
            sort:"排序", sortName:"名称", sortDate:"添加日期", sortRating:"评分",
            nightMode:"夜晚模式", clock:"显示时钟", language:"语言",
            appearance:"外观设置",
            exportDefaultName:"galgame游玩记录",
            yearStr:"年", monthStr:"月", dayStr:"日", lunarPrefix:"农历",
            noMatchGame:"没找到匹配的游戏", emptyGameList:"还没有游戏\n点上方「➕ 添加」开始记录",
            fileBtn:"文件", warnTitle:"提示", selectCoverPic:"选择封面图片",
            exampleLabel:"示例：", importTip:"提示：cover_path 为空则显示无图；types 为 TAG 的 JSON 数组字符串格式；start_date/finish_date 为游玩日期，格式 YYYY-MM-DD（如 2026-07-17）",
            aaBbText:"AaBb 文字", aaBbDesc:"AaBb 说明",
            cBlue:"天蓝", cGreen:"绿", cYellow:"黄", cPink:"粉", cBlack:"黑", cGray:"灰", cWhite:"白",
            playDate:"游玩日期", selectDate:"点击选择日期", toDate:"到", clearDate:"清除", confirm:"确定", noDate:"未设置", sun:"日", mon:"一", tue:"二", wed:"三", thu:"四", fri:"五", sat:"六",
            importTitle:"导入说明", exportTitle:"选择导出格式", file:"文件",
            deleteBg:"删除背景图片", bgHistory:"背景图片历史",
            editBg:"修改背景效果", crop:"选择背景区域",
            customAccent:"选择主题强调色", customBg:"选择背景颜色",
            useFull:"使用", cropBtn:"裁剪",
            themeColor:"主题颜色", customMode:"自定义模式",
            accentColor:"主题强调色", bgColor:"背景颜色",
            bgImage:"背景图片/视频", bgOpacity:"背景透明度", bgBlur:"背景模糊度",
            selectImage:"选择图片/视频", cropBg:"裁剪背景", bgHistoryBtn:"历史背景",
            clearBg:"清除背景", effectPreview:"效果预览",
            videoMuted:"静音", videoSound:"声音",
            videoVolume:"音量", videoSoundModule:"视频背景声音",
            videoRate:"倍速", videoPlay:"播放", videoPause:"暂停",
            dragToMove:"拖拽选区移动，拖拽四角/四边缩放，任意比例",
            hexCode:"十六进制色码", presetColors:"预设颜色",
            clickToSelect:"拖动 SV 方块和色相条选色，或点击预设色块，也可直接输入十六进制颜色码（如 #3A9FFF）",
            customDisabledDark:"黑夜模式下不可用",
            selectFileToImport:"选择文件导入", close:"关闭",
            exportFormat:"选择导出格式",
            jsonFormat:"JSON（.json）— 完整结构化，可备份/导入",
            txtFormat:"TXT（.txt）— 纯文本，方便阅读",
            csvFormat:"Excel（.csv）— 表格，Excel/WPS 可打开",
            importDesc:"导入文件为 JSON 格式（本程序导出的 .json 可直接导入）。完整字段：name、cover_path、types（TAG 数组）、rating、status、start_date（开始日期）、finish_date（结束日期）、notes。",
            exportTo:"导出到...", importFrom:"从...导入",
            gameDetail:"游戏详情", memories:"回忆",
            addScreenshot:"添加回忆", delScreenshot:"删除回忆", add:"添加",
            noScreenshots:"暂无回忆，点击「添加回忆」开始收藏",
            memoryRoot:"回忆根目录", selectFolder:"选择文件夹",
            memoryRootNotSet:"请先设置回忆根目录",
            importScreenshotFail:"回忆导入失败",
            confirmDeleteScreenshot:"确定删除这条回忆吗？",
            textColor:"文本颜色", mainTextColor:"主文本色", subTextColor:"次要文本色",
            customText:"自定义文本色",
            editMemories:"编辑回忆", playInterval:"播放间隔", fadeDuration:"淡入淡出",
            seconds:"秒",
            moveUp:"上移", moveDown:"下移", preview:"预览",
            editCover:"编辑封面", coverCrop:"裁剪封面", replaceCover:"替换封面",
            backToDetail:"返回详情", imageScale:"缩放", resetScale:"重置缩放", fitMode:"适配", cropMode:"填充",
            imagePosition:"位置", resetPosition:"重置位置",
            carousel:"轮播",
            displayMode:"展示模式", gridMode:"网格", carouselMode:"轮播",
            clickToEdit:"点击编辑", editName:"编辑名称", editRating:"编辑评分", editNotes:"编辑评价", editCover:"编辑封面", saveNotes:"保存", cancelEdit:"取消",
            gameNotes:"游戏评价", playbackOrder:"播放顺序", deleteMemory:"删除",
            dragToAdjustPos:"拖拽图片调整位置", dragToReorder:"拖拽排序",
            rotate:"旋转", resetRotate:"重置旋转", brightness:"亮度", contrast:"对比度",
            resetAll:"全部重置",
            tagTitle:"选择游戏 TAG", tagSystem:"系统默认 TAG", tagCustom:"用户自定义 TAG", tagSearch:"搜索 / 输入新 TAG", tagAdd:"新增 TAG", tagExists:"该 TAG 已存在", tagSelected:"已选", selectTag:"选 TAG", noTagHint:"未选择 TAG，点击右侧按钮选择",
            weekdays:["星期日","星期一","星期二","星期三","星期四","星期五","星期六"]
        },
        zh_TW: {
            appTitle:"galgame 遊玩記錄", add:"➕ 新增", stats:"📊 統計",
            exportBtn:"⬆ 匯出", importBtn:"⬇ 匯入",
            search:"🔍 搜尋遊戲名稱...", addTitle:"新增遊戲",
            name:"遊戲名稱（如：CLANNAD）",
            type:"TAG，空格分隔（如：校園 戀愛）", rating:"評分 0-10（如：9.3）",
            selectCover:"選擇封面", notes:"評價/感想...", save:"儲存",
            totalGames:"總遊戲", avgScore:"平均分", todo:"待玩",
            playing:"進行中", done:"已完成", edit:"編輯", del:"刪除",
            noCover:"無圖", editTitle:"編輯遊戲", deleteTitle:"刪除遊戲",
            statsTitle:"數據統計", saveModify:"儲存修改",
            deleteConfirm:"確定刪除「%1」嗎？\n此操作不可撤銷。",
            warnName:"請填寫遊戲名稱", warnType:"請選擇 TAG（如：校園）",
            warnRating:"評分請填 0–10 的數字",
            sort:"排序", sortName:"名稱", sortDate:"新增日期", sortRating:"評分",
            nightMode:"夜間模式", clock:"顯示時鐘", language:"語言",
            appearance:"外觀設定",
            exportDefaultName:"galgame遊玩記錄",
            yearStr:"年", monthStr:"月", dayStr:"日", lunarPrefix:"農曆",
            noMatchGame:"沒找到匹配的遊戲", emptyGameList:"還沒有遊戲\n點上方「➕ 新增」開始記錄",
            fileBtn:"檔案", warnTitle:"提示", selectCoverPic:"選擇封面圖片",
            exampleLabel:"範例：", importTip:"提示：cover_path 為空則顯示無圖；types 為 TAG 的 JSON 陣列字串格式；start_date/finish_date 為遊玩日期，格式 YYYY-MM-DD（如 2026-07-17）",
            aaBbText:"AaBb 文字", aaBbDesc:"AaBb 說明",
            cBlue:"天藍", cGreen:"綠", cYellow:"黃", cPink:"粉", cBlack:"黑", cGray:"灰", cWhite:"白",
            playDate:"遊玩日期", selectDate:"點擊選擇日期", toDate:"到", clearDate:"清除", confirm:"確定", noDate:"未設定", sun:"日", mon:"一", tue:"二", wed:"三", thu:"四", fri:"五", sat:"六",
            importTitle:"匯入說明", exportTitle:"選擇匯出格式", file:"檔案",
            deleteBg:"刪除背景圖片", bgHistory:"背景圖片歷史",
            editBg:"修改背景效果", crop:"選擇背景區域",
            customAccent:"選擇主題強調色", customBg:"選擇背景顏色",
            useFull:"使用", cropBtn:"裁剪",
            themeColor:"主題顏色", customMode:"自訂模式",
            accentColor:"主題強調色", bgColor:"背景顏色",
            bgImage:"背景圖片/影片", bgOpacity:"背景透明度", bgBlur:"背景模糊度",
            selectImage:"選擇圖片/影片", cropBg:"裁剪背景", bgHistoryBtn:"歷史背景",
            clearBg:"清除背景", effectPreview:"效果預覽",
            videoMuted:"靜音", videoSound:"聲音",
            videoVolume:"音量", videoSoundModule:"影片背景聲音",
            videoRate:"倍速", videoPlay:"播放", videoPause:"暫停",
            dragToMove:"拖曳選區移動，拖曳四角/四邊縮放，任意比例",
            hexCode:"十六進位色碼", presetColors:"預設顏色",
            clickToSelect:"點擊色塊快速選色，或點擊大色塊開啟取色器，也可直接輸入十六進位顏色碼（如 #3A9FFF）",
            pickColor:"吸管取色", escToCancel:"Esc 取消",
            customDisabledDark:"夜間模式下不可用",
            selectFileToImport:"選擇檔案匯入", close:"關閉",
            exportFormat:"選擇匯出格式",
            jsonFormat:"JSON（.json）— 完整結構化，可備份/匯入",
            txtFormat:"TXT（.txt）— 純文字，方便閱讀",
            csvFormat:"Excel（.csv）— 表格，Excel/WPS 可開啟",
            importDesc:"匯入檔案為 JSON 格式（本程式匯出的 .json 可直接匯入）。完整欄位：name、cover_path、types（TAG 陣列）、rating、status、start_date（開始日期）、finish_date（結束日期）、notes。",
            exportTo:"匯出到...", importFrom:"從...匯入",
            gameDetail:"遊戲詳情", memories:"回憶",
            addScreenshot:"新增回憶", delScreenshot:"刪除回憶", add:"新增",
            noScreenshots:"暫無回憶，點擊「新增回憶」開始收藏",
            memoryRoot:"回憶根目錄", selectFolder:"選擇資料夾",
            memoryRootNotSet:"請先設定回憶根目錄",
            importScreenshotFail:"回憶匯入失敗",
            confirmDeleteScreenshot:"確定刪除這條回憶嗎？",
            textColor:"文字顏色", mainTextColor:"主文字色", subTextColor:"次要文字色",
            customText:"自訂文字色",
            editMemories:"編輯回憶", playInterval:"播放間隔", fadeDuration:"淡入淡出",
            seconds:"秒",
            moveUp:"上移", moveDown:"下移", preview:"預覽",
            editCover:"編輯封面", coverCrop:"裁剪封面", replaceCover:"替換封面",
            backToDetail:"返回詳情", imageScale:"縮放", resetScale:"重置縮放", fitMode:"適配", cropMode:"填充",
            imagePosition:"位置", resetPosition:"重置位置",
            carousel:"輪播",
            displayMode:"展示模式", gridMode:"網格", carouselMode:"輪播",
            clickToEdit:"點擊編輯", editName:"編輯名稱", editRating:"編輯評分", editNotes:"編輯評價", editCover:"編輯封面", saveNotes:"保存", cancelEdit:"取消",
            gameNotes:"遊戲評價", playbackOrder:"播放順序", deleteMemory:"刪除",
            dragToAdjustPos:"拖曳圖片調整位置", dragToReorder:"拖曳排序",
            rotate:"旋轉", resetRotate:"重置旋轉", brightness:"亮度", contrast:"對比度",
            resetAll:"全部重置",
            tagTitle:"選擇遊戲 TAG", tagSystem:"系統預設 TAG", tagCustom:"使用者自訂 TAG", tagSearch:"搜尋 / 輸入新 TAG", tagAdd:"新增 TAG", tagExists:"該 TAG 已存在", tagSelected:"已選", selectTag:"選 TAG", noTagHint:"未選擇 TAG，點擊右側按鈕選擇",
            weekdays:["星期日","星期一","星期二","星期三","星期四","星期五","星期六"]
        },
        en: {
            appTitle:"galgame Play Log", add:"➕ Add", stats:"📊 Stats",
            exportBtn:"⬆ Export", importBtn:"⬇ Import",
            search:"🔍 Search game name...", addTitle:"Add Game",
            name:"Game name (e.g. CLANNAD)",
            type:"Types, space-separated (e.g. School Romance)",
            rating:"Rating 0-10 (e.g. 9.3)", selectCover:"Select Cover",
            notes:"Review/Notes...", save:"Save",
            totalGames:"Total", avgScore:"Average", todo:"To Play",
            playing:"Playing", done:"Done", edit:"Edit", del:"Delete",
            noCover:"No img", editTitle:"Edit Game", deleteTitle:"Delete Game",
            statsTitle:"Statistics", saveModify:"Save Changes",
            deleteConfirm:"Delete \"%1\"?\nThis cannot be undone.",
            warnName:"Please enter the game name", warnType:"Please select a TAG (e.g. School)",
            warnRating:"Rating must be 0–10",
            sort:"Sort", sortName:"Name", sortDate:"Added Date", sortRating:"Rating",
            nightMode:"Night Mode", clock:"Show Clock", language:"Language",
            appearance:"Appearance", settings:"Settings",
            exportDefaultName:"galgame Play Records",
            yearStr:"-", monthStr:"-", dayStr:"", lunarPrefix:"Lunar",
            noMatchGame:"No matching games found", emptyGameList:"No games yet\nClick「➕ Add」above to start recording",
            fileBtn:"File", warnTitle:"Notice", selectCoverPic:"Select Cover Image",
            exampleLabel:"Example:", importTip:"Tip: empty cover_path shows no image; types is a JSON array string of TAGs; start_date/finish_date is play date in YYYY-MM-DD format",
            aaBbText:"AaBb Text", aaBbDesc:"AaBb Desc",
            cBlue:"Blue", cGreen:"Green", cYellow:"Yellow", cPink:"Pink", cBlack:"Black", cGray:"Gray", cWhite:"White",
            playDate:"Play Date", selectDate:"Click to select date", toDate:"to", clearDate:"Clear", confirm:"OK", noDate:"Not set", sun:"Sun", mon:"Mon", tue:"Tue", wed:"Wed", thu:"Thu", fri:"Fri", sat:"Sat",
            importTitle:"Import Guide", exportTitle:"Select Export Format", file:"File",
            deleteBg:"Delete Background", bgHistory:"Background History",
            editBg:"Edit Background", crop:"Select Crop Area",
            customAccent:"Select Accent Color", customBg:"Select Background Color",
            useFull:"Use", cropBtn:"Crop",
            themeColor:"Theme Color", customMode:"Custom Mode",
            accentColor:"Accent Color", bgColor:"Background Color",
            bgImage:"Background Image", bgOpacity:"Opacity", bgBlur:"Blur",
            selectImage:"Select Image/Video", cropBg:"Crop Background", bgHistoryBtn:"History",
            clearBg:"Clear Background", effectPreview:"Effect Preview",
            videoMuted:"Muted", videoSound:"Sound",
            videoVolume:"Volume", videoSoundModule:"Video Background Sound",
            videoRate:"Speed", videoPlay:"Play", videoPause:"Pause",
            dragToMove:"Drag to move selection, drag corners/edges to resize",
            hexCode:"Hex Code", presetColors:"Preset Colors",
            clickToSelect:"Click swatches to select, or click large swatch to open color picker, or enter hex code (e.g. #3A9FFF)",
            customDisabledDark:"Not available in Night Mode",
            selectFileToImport:"Select File to Import", close:"Close",
            exportFormat:"Select Export Format",
            jsonFormat:"JSON (.json) — Complete structure, for backup/import",
            txtFormat:"TXT (.txt) — Plain text, easy to read",
            csvFormat:"Excel (.csv) — Table format, openable in Excel/WPS",
            importDesc:"Import file must be JSON format (.json exported by this app can be imported directly). Complete fields: name, cover_path, types (TAG array), rating, status, start_date (start date), finish_date (finish date), notes.",
            exportTo:"Export to...", importFrom:"Import from...",
            gameDetail:"Game Details", memories:"Memories",
            addScreenshot:"Add Memory", delScreenshot:"Delete Memory", add:"Add",
            noScreenshots:"No memories yet. Click \"Add Memory\" to start collecting.",
            memoryRoot:"Memory Root", selectFolder:"Select Folder",
            memoryRootNotSet:"Please set memory root first",
            importScreenshotFail:"Memory import failed",
            confirmDeleteScreenshot:"Delete this memory?",
            textColor:"Text Color", mainTextColor:"Main Text", subTextColor:"Secondary Text",
            customText:"Custom Text Color",
            editMemories:"Edit Memories", playInterval:"Interval", fadeDuration:"Fade",
            seconds:"s",
            moveUp:"Up", moveDown:"Down", preview:"Preview",
            editCover:"Edit Cover", coverCrop:"Crop Cover", replaceCover:"Replace Cover",
            backToDetail:"Back to Details", imageScale:"Scale", resetScale:"Reset Scale", fitMode:"Fit", cropMode:"Crop",
            imagePosition:"Position", resetPosition:"Reset Position",
            carousel:"Carousel",
            displayMode:"Display", gridMode:"Grid", carouselMode:"Carousel",
            clickToEdit:"Click to edit", editName:"Edit Name", editRating:"Edit Rating", editNotes:"Edit Notes", editCover:"Edit Cover", saveNotes:"Save", cancelEdit:"Cancel",
            gameNotes:"Notes", playbackOrder:"Order", deleteMemory:"Delete",
            dragToAdjustPos:"Drag image to adjust position", dragToReorder:"Drag to reorder",
            rotate:"Rotate", resetRotate:"Reset Rotate", brightness:"Brightness", contrast:"Contrast",
            resetAll:"Reset All",
            tagTitle:"Select Game TAG", tagSystem:"System Default TAG", tagCustom:"User Custom TAG", tagSearch:"Search / Enter new TAG", tagAdd:"Add TAG", tagExists:"This TAG already exists", tagSelected:"Selected", selectTag:"Select TAG", noTagHint:"No TAG selected, click button to choose",
            weekdays:["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
        },
        ja: {
            appTitle:"galgameプレイ記録", add:"➕ 追加", stats:"📊 統計",
            exportBtn:"⬆ 書出", importBtn:"⬇ 読込",
            search:"🔍 ゲーム名を検索...", addTitle:"ゲーム追加",
            name:"ゲーム名（例：CLANNAD）",
            type:"タイプ（スペース区切り、例：学園 恋愛）",
            rating:"評価 0-10（例：9.3）", selectCover:"カバー選択",
            notes:"感想/メモ...", save:"保存",
            totalGames:"合計", avgScore:"平均", todo:"未プレイ",
            playing:"プレイ中", done:"完了", edit:"編集", del:"削除",
            noCover:"画像なし", editTitle:"ゲーム編集", deleteTitle:"ゲーム削除",
            statsTitle:"統計", saveModify:"変更保存",
            deleteConfirm:"「%1」を削除しますか？\n元に戻せません。",
            warnName:"ゲーム名を入力してください",
            warnType:"タイプを入力してください",
            warnRating:"評価は 0–10 の数値で",
            sort:"並び替え", sortName:"名前", sortDate:"追加日", sortRating:"評価",
            nightMode:"ダークモード", clock:"時計表示", language:"言語",
            appearance:"外観設定",
            exportDefaultName:"galgameプレイ記録",
            yearStr:"年", monthStr:"月", dayStr:"日", lunarPrefix:"農暦",
            noMatchGame:"一致するゲームが見つかりません", emptyGameList:"まだゲームがありません\n上の「➕ 追加」をクリックして記録を開始",
            fileBtn:"ファイル", warnTitle:"通知", selectCoverPic:"カバー画像選択",
            exampleLabel:"例：", importTip:"ヒント：cover_path が空なら画像なし；types は TAG の JSON 配列文字列；start_date/finish_date はプレイ日付、YYYY-MM-DD 形式（例：2026-07-17）",
            aaBbText:"AaBb テキスト", aaBbDesc:"AaBb 説明",
            cBlue:"青", cGreen:"緑", cYellow:"黄", cPink:"ピンク", cBlack:"黒", cGray:"灰", cWhite:"白",
            playDate:"プレイ日付", selectDate:"クリックで日付選択", toDate:"〜", clearDate:"クリア", confirm:"確定", noDate:"未設定", sun:"日", mon:"月", tue:"火", wed:"水", thu:"木", fri:"金", sat:"土",
            importTitle:"インポートガイド", exportTitle:"書出し形式選択", file:"ファイル",
            deleteBg:"背景画像削除", bgHistory:"背景履歴",
            editBg:"背景編集", crop:"切抜き領域選択",
            customAccent:"アクセントカラー選択", customBg:"背景色選択",
            useFull:"使用", cropBtn:"切抜き",
            themeColor:"テーマカラー", customMode:"カスタムモード",
            accentColor:"アクセントカラー", bgColor:"背景色",
            bgImage:"背景画像/動画", bgOpacity:"透明度", bgBlur:"ぼかし",
            selectImage:"画像/動画選択", cropBg:"背景切抜き", bgHistoryBtn:"履歴",
            clearBg:"背景クリア", effectPreview:"効果プレビュー",
            videoMuted:"ミュート", videoSound:"音声",
            videoVolume:"音量", videoSoundModule:"動画背景サウンド",
            videoRate:"再生速度", videoPlay:"再生", videoPause:"一時停止",
            dragToMove:"選択領域をドラッグ移動、四隅/四辺をドラッグしてサイズ変更",
            hexCode:"16進コード", presetColors:"プリセットカラー",
            clickToSelect:"SVブロックと色相バーをドラッグして選択、またはスウォッチをクリック、または16進コードを直接入力（例：#3A9FFF）",
            customDisabledDark:"夜間モードでは使用不可",
            selectFileToImport:"ファイルを選択してインポート", close:"閉じる",
            exportFormat:"書出し形式選択",
            jsonFormat:"JSON（.json）— 完全構造化、バックアップ/インポート用",
            txtFormat:"TXT（.txt）— プレーンテキスト、閲覧用",
            csvFormat:"Excel（.csv）— 表形式、Excel/WPSで開ける",
            importDesc:"インポートファイルはJSON形式（このアプリケーションがエクスポートした.jsonを直接インポート可能）。完全なフィールド：name、cover_path、types（TAG 配列）、rating、status、start_date（開始日）、finish_date（終了日）、notes。",
            exportTo:"書出し先...", importFrom:"読込元...",
            gameDetail:"ゲーム詳細", memories:"思い出",
            addScreenshot:"思い出追加", delScreenshot:"思い出削除", add:"追加",
            noScreenshots:"思い出がありません。「追加」をクリックして收藏を開始",
            memoryRoot:"思い出ルート", selectFolder:"フォルダ選択",
            memoryRootNotSet:"先に思い出ルートを設定してください",
            importScreenshotFail:"思い出のインポートに失敗しました",
            confirmDeleteScreenshot:"この思い出を削除しますか？",
            textColor:"文字色", mainTextColor:"メイン文字色", subTextColor:"サブ文字色",
            customText:"カスタム文字色",
            editMemories:"思い出を編集", playInterval:"再生間隔", fadeDuration:"フェード",
            seconds:"秒",
            moveUp:"上へ", moveDown:"下へ", preview:"プレビュー",
            editCover:"カバー編集", coverCrop:"カバー切抜き", replaceCover:"カバー差替",
            backToDetail:"詳細に戻る", imageScale:"縮尺", resetScale:"リセット", fitMode:"フィット", cropMode:"クロップ",
            imagePosition:"位置", resetPosition:"位置リセット",
            carousel:"スライド",
            displayMode:"表示モード", gridMode:"グリッド", carouselMode:"スライド",
            clickToEdit:"クリック編集", editName:"名前編集", editRating:"評価編集", editNotes:"メモ編集", editCover:"カバー編集", saveNotes:"保存", cancelEdit:"キャンセル",
            gameNotes:"メモ", playbackOrder:"順序", deleteMemory:"削除",
            dragToAdjustPos:"画像をドラッグして位置調整", dragToReorder:"ドラッグで並べ替え",
            rotate:"回転", resetRotate:"回転リセット", brightness:"明るさ", contrast:"コントラスト",
            resetAll:"全リセット",
            tagTitle:"ゲーム TAG 選択", tagSystem:"システム既定 TAG", tagCustom:"ユーザー自定义 TAG", tagSearch:"検索 / 新規 TAG 入力", tagAdd:"TAG 追加", tagExists:"この TAG は既に存在します", tagSelected:"選択済", selectTag:"TAG 選択", noTagHint:"TAG 未選択、右ボタンをクリックして選択",
            weekdays:["日曜日","月曜日","火曜日","水曜日","木曜日","金曜日","土曜日"]
        }
    })
    function tt(key, arg) {
        var s = (tr[currentLang] && tr[currentLang][key]) ? tr[currentLang][key] : key;
        if (arg !== undefined) s = s.replace("%1", arg);
        return s;
    }

    // === 主题色系 ===
    readonly property var themeBg: ({
        light: { blue:"#e8f0fe", green:"#e6f4ea", yellow:"#fef7e0", pink:"#fce4ec", black:"#f0f0f0", gray:"#f5f5f5", white:"#fafafa", custom:"#f5f5f8" },
        dark:  { blue:"#0d1b2a", green:"#0d1f12", yellow:"#1f1b0d", pink:"#1f0d14", black:"#1a1a1a", gray:"#1f1f1f", white:"#242424", custom:"#1a1a24" }
    })
    property color cBg: currentTheme === "custom" ? customBgColor
        : themeBg[isDark ? "dark" : "light"][currentTheme] || (isDark ? "#1a1a24" : "#f5f5f8")
    // 自定义模式下按 customBgColor 亮度判断深浅，使卡片/输入框/文字色与背景协调
    readonly property real customBgLuminance: 0.299 * customBgColor.r + 0.587 * customBgColor.g + 0.114 * customBgColor.b
    readonly property bool customIsDarkBg: customBgLuminance < 0.5
    readonly property bool effDark: currentTheme === "custom" ? customIsDarkBg : isDark
    readonly property color cCard:   effDark ? "#252533" : "#ffffff"
    readonly property color cInput:  effDark ? "#2a2a3a" : "#ffffff"
    // 自定义模式时使用用户定义的文本颜色；否则用默认深浅色
    property color cText: currentTheme === "custom" ? (customTextColorSet ? customTextColor : (effDark ? "#e8e8ec" : "#222222"))
        : (isDark ? "#e8e8ec" : "#222222")
    property color cSub:  currentTheme === "custom" ? (customSubColorSet ? customSubColor : (effDark ? "#9999aa" : "#666666"))
        : (isDark ? "#9999aa" : "#666666")
    readonly property color cBorder: effDark ? "#3a3a4e" : "#e0e0e0"
    property string currentTheme: "blue"
    // 自定义主题色（默认天蓝）
    property color customAccent: "#3a9fff"
    // 自定义背景色（默认透明的淡蓝色，与 blue 主题背景一致）
    property color customBgColor: "#e8f0fe"
    // 自定义文本颜色
    property color customTextColor: "#222222"
    property color customSubColor: "#666666"
    property bool customTextColorSet: false   // 是否已自定义主文本色
    property bool customSubColorSet: false    // 是否已自定义次要文本色
    property string bgImagePath: ""
    property real bgOpacity: 0.35
    property real bgBlur: 0.5
    property bool bgVideoMuted: true   // 视频背景静音模式（默认静音）
    property real bgVideoVolume: 1.0   // 视频背景音量（0.0-1.0）
    property real bgVideoRate: 1.0   // 视频背景播放速度（0.25-3.0），持久化（用户偏好）
    property bool bgVideoPaused: false   // 视频背景手动暂停（临时控制，不持久化；切换视频自动播放）
    property int currentBgHistoryId: -1   // 当前背景对应的历史记录 ID（-1=未对应历史记录）
    // 游戏 TAG 系统：系统默认 31 个 + 用户自定义（持久化到数据库 customTags 键，JSON 数组）
    readonly property var systemTags: ["R18","恋爱","校园","剧情作","百合","废萌","女装","异世界","后宫","奇幻","超能力","悬疑","冒险","萝莉","妹妹","纯爱","NTR","魔法","姐姐","凌辱","治愈","致郁","搞笑","日常","伪娘","背德","喜剧","傲娇","兽耳","单线结局","多线结局"]
    property var customTags: []   // 用户自定义 TAG 列表（持久化）
    readonly property var themeAccents: ({
        light: { blue:"#3a9fff", green:"#3fb958", yellow:"#f0b400", pink:"#ff7aa8", black:"#3a3a3a", gray:"#888888", white:"#bbbbbb", custom:customAccent },
        dark:  { blue:"#5db5ff", green:"#5dd474", yellow:"#ffc94d", pink:"#ff9ac0", black:"#666666", gray:"#999999", white:"#e8e8e8", custom:customAccent }
    })
    readonly property color cAccent: currentTheme === "custom" ? customAccent
        : themeAccents[isDark ? "dark" : "light"][currentTheme] || "#3a9fff"

    palette.window: cBg; palette.windowText: cText; palette.base: cInput
    palette.alternateBase: cCard; palette.text: cText; palette.buttonText: cText
    palette.button: cCard; palette.light: cCard; palette.mid: cBorder
    palette.dark: cBorder; palette.highlight: cAccent; palette.highlightedText: "#ffffff"
    palette.placeholderText: cSub

    DatabaseManager { id: dbManager }
    GameListModel { id: gameListModel }

    // ===== 外观设置持久化（方案C：存入 app_settings 表，与回忆根目录等设置统一）=====
    // 启动时从数据库加载所有持久化设置
    function loadAppearance() {
        var v;
        v = dbManager.getSetting("language"); if (v.length > 0) root.currentLang = v;
        v = dbManager.getSetting("theme"); if (v.length > 0) root.currentTheme = v;
        v = dbManager.getSetting("isDark"); if (v.length > 0) root.isDark = (v === "1");
        v = dbManager.getSetting("lastTheme"); if (v.length > 0) root.lastTheme = v;
        v = dbManager.getSetting("preCustomTheme"); if (v.length > 0) root.preCustomTheme = v;
        v = dbManager.getSetting("clockVisible"); if (v.length > 0) root.clockVisible = (v === "1");
        v = dbManager.getSetting("customAccent"); if (v.length > 0) root.customAccent = v;
        v = dbManager.getSetting("customBgColor"); if (v.length > 0) root.customBgColor = v;
        v = dbManager.getSetting("customTextColor"); if (v.length > 0) root.customTextColor = v;
        v = dbManager.getSetting("customSubColor"); if (v.length > 0) root.customSubColor = v;
        v = dbManager.getSetting("customTextColorSet"); if (v.length > 0) root.customTextColorSet = (v === "1");
        v = dbManager.getSetting("customSubColorSet"); if (v.length > 0) root.customSubColorSet = (v === "1");
        v = dbManager.getSetting("bgImagePath"); if (v.length > 0) root.bgImagePath = v;
        // 启动时延迟查询 currentBgHistoryId（避免阻塞启动加载）
        if (v.length > 0) bgHistoryIdTimer.start()
        v = dbManager.getSetting("bgOpacity"); if (v.length > 0) root.bgOpacity = parseFloat(v);
        v = dbManager.getSetting("bgBlur"); if (v.length > 0) root.bgBlur = parseFloat(v);
        v = dbManager.getSetting("bgVideoMuted"); if (v.length > 0) root.bgVideoMuted = (v === "1");
        v = dbManager.getSetting("bgVideoVolume"); if (v.length > 0) root.bgVideoVolume = parseFloat(v);
        v = dbManager.getSetting("bgVideoRate"); if (v.length > 0) root.bgVideoRate = parseFloat(v);
        // 加载用户自定义 TAG（JSON 数组持久化）
        v = dbManager.getSetting("customTags");
        if (v.length > 0) {
            try { root.customTags = JSON.parse(v) } catch(e) { root.customTags = [] }
        }
        // bgVideoPaused 不持久化（临时控制，启动时默认 false 自动播放）
    }

    Component.onCompleted: {
        dbManager.initializeDatabase();
        loadAppearance();
        reloadList(); refreshStats(); refreshMainPie();
    }
    // 启动时延迟查询 currentBgHistoryId（避免在 loadAppearance 中同步查询阻塞）
    Timer {
        id: bgHistoryIdTimer
        interval: 50; repeat: false
        onTriggered: {
            var foundId = -1
            var normPath = root.bgImagePath.replace(/\\/g, "/")
            var imgs = dbManager.getBgImages()
            for (var i = 0; i < imgs.length; i++) {
                if (imgs[i].imagePath.replace(/\\/g, "/") === normPath) { foundId = imgs[i].id; break }
            }
            root.currentBgHistoryId = foundId
        }
    }

    // 属性变化时自动持久化到数据库
    onCurrentLangChanged: {
        dbManager.setSetting("language", root.currentLang);
        reloadList();      // 刷新列表（状态文本翻译）
        refreshStats();    // 刷新饼图标签翻译
    }
    onCurrentThemeChanged: dbManager.setSetting("theme", root.currentTheme)
    onIsDarkChanged: dbManager.setSetting("isDark", root.isDark ? "1" : "0")
    onLastThemeChanged: dbManager.setSetting("lastTheme", root.lastTheme)
    onPreCustomThemeChanged: dbManager.setSetting("preCustomTheme", root.preCustomTheme)
    onClockVisibleChanged: dbManager.setSetting("clockVisible", root.clockVisible ? "1" : "0")
    onCustomAccentChanged: dbManager.setSetting("customAccent", root.customAccent.toString())
    onCustomBgColorChanged: dbManager.setSetting("customBgColor", root.customBgColor.toString())
    onCustomTextColorChanged: dbManager.setSetting("customTextColor", root.customTextColor.toString())
    onCustomSubColorChanged: dbManager.setSetting("customSubColor", root.customSubColor.toString())
    onCustomTextColorSetChanged: dbManager.setSetting("customTextColorSet", root.customTextColorSet ? "1" : "0")
    onCustomSubColorSetChanged: dbManager.setSetting("customSubColorSet", root.customSubColorSet ? "1" : "0")
    onBgImagePathChanged: {
        dbManager.setSetting("bgImagePath", root.bgImagePath)
        // currentBgHistoryId 由各设置 bgImagePath 的位置直接设置（避免同步数据库查询阻塞 QML 绑定更新）
        // 清除背景时设为 -1，历史背景点击时设为 modelData.id，其他位置设为 -1
    }
    onBgOpacityChanged: {
        dbManager.setSetting("bgOpacity", root.bgOpacity.toString())
        // 同步更新历史记录中对应背景的透明度
        if (root.currentBgHistoryId >= 0) dbManager.updateBgImage(root.currentBgHistoryId, root.bgOpacity, root.bgBlur)
    }
    onBgBlurChanged: {
        dbManager.setSetting("bgBlur", root.bgBlur.toString())
        // 同步更新历史记录中对应背景的模糊度
        if (root.currentBgHistoryId >= 0) dbManager.updateBgImage(root.currentBgHistoryId, root.bgOpacity, root.bgBlur)
    }
    onBgVideoMutedChanged: dbManager.setSetting("bgVideoMuted", root.bgVideoMuted ? "1" : "0")
    onBgVideoVolumeChanged: dbManager.setSetting("bgVideoVolume", root.bgVideoVolume.toString())
    onBgVideoRateChanged: dbManager.setSetting("bgVideoRate", root.bgVideoRate.toString())
    // bgVideoPaused 不持久化

    function jsonToText(jsonStr) { try { return JSON.parse(jsonStr).join(" "); } catch(e) { return jsonStr; } }
    function urlToPath(u) {
        var s = u.toString();
        if (s.startsWith("file:///")) s = s.substring(8);
        else if (s.startsWith("file://")) s = s.substring(7);
        try { s = decodeURIComponent(s); } catch(e) {}
        return s;
    }
    // 判断是否为视频文件（仅支持 MP4）
    function isVideoFile(path) {
        return path.toLowerCase().endsWith(".mp4");
    }
    // 毫秒时间转 mm:ss 格式（视频进度条时间显示）
    function formatTime(ms) {
        if (!ms || ms <= 0) return "00:00"
        var s = Math.floor(ms / 1000)
        var m = Math.floor(s / 60)
        s = s % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }
    // 游戏状态：数据库统一存中文（待玩/进行中/已完成），显示时通过本函数翻译
    readonly property var statusKeys: ["待玩", "进行中", "已完成"]
    function statusText(s) {
        if (s === "待玩") return tt("todo");
        if (s === "进行中") return tt("playing");
        if (s === "已完成") return tt("done");
        return s;
    }
    // 主页游戏卡片：tag 最多展示5个，超出显示"…"，并拼接状态文本
    function formatTagsWithStatus(typesJson, status) {
        var arr = jsonToText(typesJson).split(/\s+/).filter(function(s){return s.length>0})
        var shown = arr.slice(0, 5).join(" ")
        if (arr.length > 5) shown += " …"
        return shown + "   ·   " + statusText(status)
    }
    // ===== 日期格式化 helper =====
    // YYYY-MM-DD → "20xx年x月x日"，空字符串返回空
    function formatDate(dateStr) {
        if (!dateStr || dateStr.length === 0) return ""
        var parts = dateStr.split("-")
        if (parts.length !== 3) return dateStr
        return parts[0] + tt("yearStr") + parseInt(parts[1], 10) + tt("monthStr") + parseInt(parts[2], 10) + tt("dayStr")
    }
    // Date 对象 → "YYYY-MM-DD" 字符串
    function dateToYMD(date) {
        if (!date) return ""
        var y = date.getFullYear()
        var m = date.getMonth() + 1
        var d = date.getDate()
        return y + "-" + (m < 10 ? "0" + m : m) + "-" + (d < 10 ? "0" + d : d)
    }
    // "YYYY-MM-DD" → Date 对象
    function ymdToDate(dateStr) {
        if (!dateStr || dateStr.length === 0) return new Date()
        var parts = dateStr.split("-")
        if (parts.length !== 3) return new Date()
        return new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10))
    }
    // 农历转换
    readonly property var lunarInfo: [0x04bd8,0x04ae0,0x0a570,0x054d5,0x0d260,0x0d950,0x16554,0x056a0,0x09ad0,0x055d2,0x04ae0,0x0a5b6,0x0a4d0,0x0d250,0x1d255,0x0b540,0x0d6a0,0x0ada2,0x095b0,0x14977,0x04970,0x0a4b0,0x0b4b5,0x06a50,0x06d40,0x1ab54,0x02b60,0x09570,0x052f2,0x04970,0x06566,0x0d4a0,0x0ea50,0x06e95,0x05ad0,0x02b60,0x186e3,0x092e0,0x1c8d7,0x0c950,0x0d4a0,0x1d8a6,0x0b550,0x056a0,0x1a5b4,0x025d0,0x092d0,0x0d2b2,0x0a950,0x0b557,0x06ca0,0x0b550,0x15355,0x04da0,0x0a5b0,0x14573,0x052b0,0x0a9a8,0x0e950,0x06aa0,0x0aea6,0x0ab50,0x04b60,0x0aae4,0x0a570,0x05260,0x0f263,0x0d950,0x05b57,0x056a0,0x096d0,0x04dd5,0x04ad0,0x0a4d0,0x0d4d4,0x0d250,0x0d558,0x0b540,0x0b6a0,0x195a6,0x095b0,0x049b0,0x0a974,0x0a4b0,0x0b27a,0x06a50,0x06d40,0x0af46,0x0ab60,0x09570,0x04af5,0x04970,0x064b0,0x074a3,0x0ea50,0x06b58,0x055c0,0x0ab60,0x096d5,0x092e0,0x0c960,0x0d954,0x0d4a0,0x0da50,0x07552,0x056a0,0x0abb7,0x025d0,0x092d0,0x0cab5,0x0a950,0x0b4a0,0x0baa4,0x0ad50,0x055d9,0x04ba0,0x0a5b0,0x15176,0x052b0,0x0a930,0x07954,0x06aa0,0x0ad50,0x05b52,0x04b60,0x0a6e6,0x0a4e0,0x0d260,0x0ea65,0x0d530,0x05aa0,0x076a3,0x096d0,0x04afb,0x04ad0,0x0a4d0,0x1d0b6,0x0d250,0x0d520,0x0dd45,0x0b5a0,0x056d0,0x055b2,0x049b0,0x0a577,0x0a4b0,0x0aa50,0x1b255,0x06d20,0x0ada0]
    function _leapMonth(y) { return root.lunarInfo[y - 1900] & 0xf; }
    function _leapDays(y) { return root._leapMonth(y) ? ((root.lunarInfo[y - 1900] & 0x10000) ? 30 : 29) : 0; }
    function _monthDays(y, m) { return (root.lunarInfo[y - 1900] & (0x10000 >> m)) ? 30 : 29; }
    function _lYearDays(y) { var sum = 348; for (var i = 0x8000; i > 0x8; i >>= 1) { if (root.lunarInfo[y - 1900] & i) sum++; } return sum + root._leapDays(y); }
    function getLunarDate(date) {
        var offset = Math.floor((date - new Date(1900, 0, 31)) / 86400000);
        var i, temp = 0, y;
        for (i = 1900; i < 2100 && offset > 0; i++) { temp = root._lYearDays(i); offset -= temp; }
        if (offset < 0) { offset += temp; i--; }
        y = i;
        var leap = root._leapMonth(y), isLeap = false;
        for (i = 1; i < 13 && offset >= 0; i++) {
            if (leap > 0 && i === (leap + 1) && !isLeap) { --i; isLeap = true; temp = root._leapDays(y); }
            else { temp = root._monthDays(y, i); }
            if (isLeap && i === (leap + 1)) isLeap = false;
            if (offset < temp) break;
            offset -= temp;
        }
        var m = i, d = offset + 1;
        var mn = ["正","二","三","四","五","六","七","八","九","十","冬","腊"];
        var dn = ["初一","初二","初三","初四","初五","初六","初七","初八","初九","初十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十","廿一","廿二","廿三","廿四","廿五","廿六","廿七","廿八","廿九","三十"];
        return (isLeap ? "闰" : "") + mn[m - 1] + "月" + dn[d - 1];
    }
    function getWeekday(date) {
        var w = root.tr[root.currentLang].weekdays;
        return w[date.getDay()];
    }
    function refreshStats() {
        root.totalCount = dbManager.getGameCount();
        var sc = dbManager.getStatusCounts();
        root.todoCount = sc["待玩"] || 0; root.playingCount = sc["进行中"] || 0; root.doneCount = sc["已完成"] || 0;
        refreshMainPie();
    }
    function refreshMainPie() {
        if (!mainPieSeries) return;
        mainPieSeries.clear();
        var statusList = [
            { name: tt("todo"), count: root.todoCount, color: "#ffb84d" },
            { name: tt("playing"), count: root.playingCount, color: "#4d9fff" },
            { name: tt("done"), count: root.doneCount, color: "#5bd06d" }
        ];
        for (var i = 0; i < statusList.length; i++) {
            if (statusList[i].count > 0) {
                mainPieSeries.append(statusList[i].name, statusList[i].count);
                mainPieSeries.at(mainPieSeries.count - 1).color = statusList[i].color;
                mainPieSeries.at(mainPieSeries.count - 1).labelColor = cText;
            }
        }
    }
    function warn(msg) { warnDialog.text = msg; warnDialog.open(); }
    MessageDialog { id: warnDialog; title: tt("warnTitle"); text: "" }

    // ===== 内联组件 =====

    component DragHeader: Rectangle {
        width: parent.width; height: 36; color: cAccent; radius: 6
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 6; color: cAccent }
        property alias titleText: headerLabel.text
        property Dialog dragTarget: null
        Connections {
            target: dragTarget
            function onOpened() { dragTarget.x = (root.width - dragTarget.width) / 2; dragTarget.y = (root.height - dragTarget.height) / 2; }
        }
        Label { id: headerLabel; anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; color: "#ffffff"; font.bold: true; font.pixelSize: 14 }
        Button { anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter; text: "✕"; flat: true; font.pixelSize: 16; onClicked: if (dragTarget) dragTarget.close(); palette.buttonText: "#ffffff" }
        MouseArea { anchors.fill: parent; anchors.rightMargin: 40; property point startPos; onPressed: startPos = Qt.point(mouseX, mouseY); onPositionChanged: { if (dragTarget) { dragTarget.x += mouseX - startPos.x; dragTarget.y += mouseY - startPos.y; } } cursorShape: Qt.SizeAllCursor }
    }

    // 通用对话框背景组件
    component DlgBg: Rectangle { color: cBg; radius: 6; border.color: cBorder; border.width: 1 }

    // Canvas 星级绘制组件：精确按比例填充，支持任意小数评分
    // property rating: 0-10  property starSize: 星形单格尺寸  property starGap: 星间距
    component StarCanvas: Canvas {
        property real rating: 0
        property real starSize: 16
        property real starGap: 2
        property color fillColor: "#ffc107"
        property color emptyColor: cSub
        readonly property real starR: starSize * 0.45   // 外半径（留边距避免裁剪）
        width: starSize * 5 + starGap * 4; height: starSize
        onRatingChanged: requestPaint()
        onFillColorChanged: requestPaint()
        onEmptyColorChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            for (var i = 0; i < 5; i++) {
                var cx = i * (starSize + starGap) + starSize / 2
                var cy = starSize / 2
                // 底层：灰色空星
                drawStar(ctx, cx, cy, starR, emptyColor)
                // 顶层：黄色填充星，按比例裁剪
                var fill = Math.max(0, Math.min(2, rating - i * 2)) / 2
                if (fill > 0) {
                    ctx.save()
                    ctx.beginPath()
                    ctx.rect(i * (starSize + starGap), 0, starSize * fill, starSize)
                    ctx.clip()
                    drawStar(ctx, cx, cy, starR, fillColor)
                    ctx.restore()
                }
            }
        }
        function drawStar(ctx, cx, cy, R, color) {
            var r = R * 0.382
            ctx.beginPath()
            for (var j = 0; j < 10; j++) {
                var radius = j % 2 === 0 ? R : r
                var angle = -Math.PI / 2 + j * Math.PI / 5
                var x = cx + radius * Math.cos(angle)
                var y = cy + radius * Math.sin(angle)
                if (j === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.closePath()
            ctx.fillStyle = color
            ctx.fill()
        }
    }

    component StarDisplay: Row {
        spacing: 0
        property real ratingValue: 0
        StarCanvas { rating: ratingValue; starSize: 16; starGap: 0 }
        Text { visible: ratingValue > 0; text: ratingValue.toFixed(1); font.pixelSize: 12; color: cSub; anchors.verticalCenter: parent.verticalCenter; leftPadding: 4 }
    }

    component StarInput: Row {
        spacing: 4
        property alias field: tf
        property real rv: tf.text ? parseFloat(tf.text) : 0
        // 星星容器：Canvas 显示 + 透明点击层叠加
        Item {
            width: 28 * 5; height: 28
            StarCanvas { rating: rv; starSize: 28; starGap: 0; anchors.centerIn: parent }
            Row {
                anchors.fill: parent; spacing: 0
                Repeater {
                    model: 5
                    Item {
                        width: 28; height: 28
                        MouseArea { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: parent.width / 2; cursorShape: Qt.PointingHandCursor; onClicked: tf.text = (index * 2 + 1).toString() }
                        MouseArea { anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: parent.width / 2; cursorShape: Qt.PointingHandCursor; onClicked: tf.text = ((index + 1) * 2).toString() }
                    }
                }
            }
        }
        TextField {
            id: tf; width: 50; placeholderText: "0.0-10.0"; selectByMouse: true
            background: InputBg {}
            validator: DoubleValidator { bottom: 0.0; top: 10.0; decimals: 1; locale: "C" }
            onTextChanged: {
                // 只允许数字和一个小数点
                var t = text.replace(/[^0-9.]/g, "");
                var parts = t.split(".");
                if (parts.length > 2) t = parts[0] + "." + parts.slice(1).join("");
                if (t !== text) text = t;
                // 实时范围限制
                var v = parseFloat(t);
                if (!isNaN(v)) {
                    if (v > 10) text = "10.0";
                    else if (v < 0) text = "0.0";
                }
            }
        }
    }

    // 主操作按钮（accent 背景 + 白字），BtnOk/BtnSave/BtnImport 仅为预设默认文案的别名
    component BtnPrimary: Button {
        id: bpBtn; highlighted: true
        background: Rectangle { color: bpBtn.hovered ? Qt.darker(cAccent, 1.2) : cAccent; radius: 4; implicitWidth: 72; implicitHeight: 32; Behavior on color { ColorAnimation { duration: 150 } } }
        palette.buttonText: "#ffffff"
    }
    component BtnOk: BtnPrimary { text: "OK" }
    component BtnSave: BtnPrimary { text: "Save" }
    component BtnImport: BtnPrimary { text: "Import" }

    component BtnCancel: Button {
        id: bcBtn; text: "Cancel"; flat: true
        background: Rectangle { color: bcBtn.hovered ? "#ff4444" : "#30ff4444"; radius: 4; border.color: "#ff4444"; border.width: 1; implicitWidth: 72; implicitHeight: 32; Behavior on color { ColorAnimation { duration: 150 } } }
        palette.buttonText: bcBtn.hovered ? "#ffffff" : "#ff4444"
    }

    component BtnClose: Button {
        id: bclBtn; text: "Close"; flat: true
        background: Rectangle { color: bclBtn.hovered ? "#ff4444" : "transparent"; radius: 4; border.color: bclBtn.hovered ? "#ff4444" : cBorder; border.width: 1; implicitWidth: 72; implicitHeight: 32; Behavior on color { ColorAnimation { duration: 150 } } }
        palette.buttonText: bclBtn.hovered ? "#ffffff" : cText
    }

    // 对话框底部按钮栏（居中）
    component FooterRow: Row {
        spacing: 8; layoutDirection: Qt.RightToLeft
        padding: 12; anchors.horizontalCenter: parent.horizontalCenter
    }

    // 圆角半透明输入框背景
    component InputBg: Rectangle {
        radius: 8; color: Qt.rgba(cText.r, cText.g, cText.b, 0.05); border.color: cBorder; border.width: 1; implicitHeight: 38
    }

    // 圆角半透明按钮
    component BtnGhost: Button {
        id: bgBtn; flat: true
        background: Rectangle { color: bgBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15); radius: 8; border.color: cAccent; border.width: 1; implicitWidth: 100; implicitHeight: 34; Behavior on color { ColorAnimation { duration: 150 } } }
        palette.buttonText: bgBtn.hovered ? "#ffffff" : cAccent
    }

    // 与主页面一致的自动隐藏滚动条
    component MainSB: ScrollBar {
        id: sb
        policy: ScrollBar.AsNeeded; width: 10; interactive: true
        opacity: 0; Behavior on opacity { NumberAnimation { duration: 200 } }
        contentItem: Rectangle { radius: 5; color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.7) }
        onHoveredChanged: { if (hovered) sb.opacity = 1.0; else sbTimer.restart() }
        onPressedChanged: { if (pressed) sb.opacity = 1.0; else sbTimer.restart() }
        Timer { id: sbTimer; interval: 800; onTriggered: if (!sb.hovered && !sb.pressed) sb.opacity = 0.0 }
    }


    // 圆形手柄滑块：细线轨道 + 主题色已选区 + 16×16 圆球手柄（root. 前缀修复子 Window 作用域问题）
    // implicitWidth/implicitHeight 必须提供，否则 Slider 在布局中 implicit 尺寸归零导致不可见
    component RoundSlider: Slider {
        id: rs
        background: Rectangle {
            x: rs.leftPadding; y: rs.topPadding + rs.availableHeight / 2 - 2
            width: rs.availableWidth; height: 4; radius: 2
            implicitWidth: 200; implicitHeight: 20
            color: Qt.rgba(root.cBorder.r, root.cBorder.g, root.cBorder.b, 0.6)
            Rectangle {
                width: rs.visualPosition * rs.availableWidth; height: parent.height; radius: 2
                color: root.cAccent
            }
        }
        handle: Rectangle {
            x: rs.leftPadding + rs.visualPosition * (rs.availableWidth - width)
            y: rs.topPadding + rs.availableHeight / 2 - height / 2
            width: 16; height: 16; radius: 8
            color: rs.pressed ? Qt.lighter(root.cAccent, 1.2) : root.cAccent
            border.color: "#ffffff"; border.width: 2
            Behavior on color { ColorAnimation { duration: 100 } }
        }
    }

    // 无框对话框拖动栏：透明背景 + 标题 + ✕关闭按钮（hover 红底白字）
    // 颜色属性用 root. 前缀访问根 Window 自定义属性（inline component 作用域限制）
    component FramelessDragBar: Rectangle {
        id: dragBar
        property var dialogWindow: null  // 关联的 Window 对象，用于关闭
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: 38; z: 50
        color: "transparent"  // 透明背景，无标题无分隔线
        // 拖动区：整个拖动栏可拖动窗口
        MouseArea { anchors.fill: parent; onPressed: { if (dialogWindow) dialogWindow.startSystemMove() } }
        // ✕ 关闭按钮（右上角，hover 红底白字）
        Button {
            id: dragBarClose
            text: "✕"; flat: true; width: 32; height: 28
            anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
            background: Rectangle {
                color: dragBarClose.hovered ? "#ff4444" : "transparent"
                radius: 6
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            palette.buttonText: dragBarClose.hovered ? "#ffffff" : root.cSub
            onClicked: { if (dialogWindow) dialogWindow.close() }
        }
    }

    component ColorPickerDialog: Window {
        id: cpSelf
        property color initialColor                     // 打开时取色的源属性
        property var presetColors: []                   // 预设色板
        property string previewText: ""                 // 预览区文字（空=纯色块）
        property color previewBgColor: selectedColor    // 预览区背景色
        property int previewFontSize: 16                // 预览区字号
        property bool previewOutline: true              // 预览区文字是否有描边
        signal accepted(color c)                        // 点击 OK 时发出

        modality: Qt.WindowModal
        transientParent: appearanceDialog
        flags: Qt.FramelessWindowHint | Qt.Window
        width: 340; height: 540
        minimumWidth: 320; minimumHeight: 520
        color: "transparent"
        x: root.x + (root.width - width) / 2
        y: root.y + (root.height - height) / 2
        palette.window: cCard; palette.windowText: cText; palette.text: cText; palette.button: cCard; palette.buttonText: cText; palette.base: cInput; palette.placeholderText: cSub; palette.highlight: cAccent; palette.highlightedText: "#ffffff"
        property color selectedColor: initialColor
        onVisibleChanged: if (visible) selectedColor = initialColor
        Rectangle { anchors.fill: parent; radius: 8; color: root.cBg }
        FramelessDragBar { dialogWindow: cpSelf }
        Flickable {
            anchors.fill: parent; anchors.margins: 12; anchors.topMargin: 38; anchors.bottomMargin: 52
            clip: true; contentWidth: width; contentHeight: pickerCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: MainSB {}
            ColumnLayout {
                id: pickerCol; width: parent.width; spacing: 10
                Rectangle { Layout.fillWidth: true; height: 40; radius: 8; color: previewBgColor; border.color: cBorder; border.width: 1
                    Text { visible: previewText !== ""; anchors.centerIn: parent; text: previewText; color: selectedColor; font.pixelSize: previewFontSize
                        style: previewOutline ? Text.Outline : Text.Normal
                        styleColor: Qt.rgba(1-selectedColor.r, 1-selectedColor.g, 1-selectedColor.b, 0.3) }
                }
                Loader {
                    id: pickerLoader
                    sourceComponent: hsvPickerComp
                    Layout.fillWidth: true; Layout.preferredHeight: 180
                    onLoaded: { item.selectedColor = selectedColor }
                }
                Connections { target: pickerLoader.item; function onSelectedColorChanged() { selectedColor = pickerLoader.item.selectedColor } }
                Binding { target: pickerLoader.item; property: "selectedColor"; value: selectedColor; when: pickerLoader.item && !pickerLoader.item.internalChange }
                Label { text: tt("presetColors"); color: cSub; font.pixelSize: 12 }
                Flow { Layout.fillWidth: true; spacing: 6
                    Repeater {
                        model: presetColors
                        delegate: Rectangle {
                            width: 28; height: 28; radius: 5; color: modelData
                            border.width: selectedColor.toString().toLowerCase() === modelData.toLowerCase() ? 3 : 1
                            border.color: selectedColor.toString().toLowerCase() === modelData.toLowerCase() ? cAccent : cBorder
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: selectedColor = modelData }
                        }
                    }
                }
                Label { text: tt("hexCode"); color: cSub; font.pixelSize: 12 }
                TextField {
                    id: hexInput; Layout.fillWidth: true
                    text: selectedColor.toString().toUpperCase()
                    placeholderText: "#RRGGBB"
                    background: InputBg {}
                    onEditingFinished: { var t = text.trim(); if (/^#[0-9a-fA-F]{6}$/.test(t) || /^#[0-9a-fA-F]{8}$/.test(t)) selectedColor = t; else text = selectedColor.toString().toUpperCase(); }
                }
            }
        }
        Row {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.margins: 12; spacing: 8
            Item { width: parent.width - 180; height: 1 }
            BtnCancel { onClicked: close() }
            BtnOk { onClicked: { accepted(selectedColor); close(); } }
        }
    }

    // ===== 背景图层（视频）— MediaPlayer + Connections =====
    // VideoOutput 已在 bgRect 内部声明（L22-27），MediaPlayer 通过 videoOutput:bgVideo 反向绑定
    MediaPlayer {
        id: bgMediaPlayer
        source: root.bgImagePath.length > 0 && isVideoFile(root.bgImagePath) ? "file:///" + root.bgImagePath.replace(/\\/g, "/") : ""
        loops: MediaPlayer.Infinite   // 循环播放
        videoOutput: bgVideo
        audioOutput: AudioOutput { id: bgAudioOutput; volume: root.bgVideoMuted ? 0.0 : root.bgVideoVolume }
        playbackRate: root.bgVideoRate   // 播放速度（0.25-3.0）
        // 视频文件且窗口可见时播放/暂停，否则停止；bgVideoPaused 由用户控制
        onSourceChanged: {
            if (root.bgImagePath.length > 0 && isVideoFile(root.bgImagePath) && root.visible) {
                if (root.bgVideoPaused) bgMediaPlayer.pause()
                else bgMediaPlayer.play()
            } else bgMediaPlayer.stop()
        }
    }
    Connections {
        target: root
        function onVisibleChanged() {
            if (root.bgImagePath.length > 0 && isVideoFile(root.bgImagePath) && root.visible) {
                if (root.bgVideoPaused) bgMediaPlayer.pause()
                else bgMediaPlayer.play()
            } else bgMediaPlayer.stop()
        }
        function onBgImagePathChanged() {
            // 切换视频时重置暂停状态（自动播放新视频）
            root.bgVideoPaused = false
            if (root.bgImagePath.length > 0 && isVideoFile(root.bgImagePath) && root.visible) bgMediaPlayer.play()
            else bgMediaPlayer.stop()
        }
        function onBgVideoPausedChanged() {
            if (root.bgImagePath.length > 0 && isVideoFile(root.bgImagePath) && root.visible) {
                if (root.bgVideoPaused) bgMediaPlayer.pause()
                else bgMediaPlayer.play()
            }
        }
    }

    // ===== 顶部工具栏（常驻显示，无边框透明，parent:bgRect 被圆角裁剪）=====
    Rectangle {
        id: toolbar
        parent: bgRect
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: 46; z: 31
        color: "transparent"; border.width: 0

        // 窗口拖动区：工具栏左侧空白区域按住可拖动窗口（startSystemMove）
        MouseArea {
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
            anchors.right: btnRow.left
            onPressed: root.startSystemMove()
        }

        Row {
            id: btnRow
            anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; spacing: 4
            // 语言切换（地球图标 + Menu 下拉）
            Button {
                id: langBtn; text: "🌍"; flat: true
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#80000000"; shadowBlur: 0.4; shadowVerticalOffset: 2 }
                background: Rectangle { color: langBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12); radius: 8; border.color: langBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4); border.width: 1; implicitHeight: 32; implicitWidth: 36; Behavior on color { ColorAnimation { duration: 150 } } }
                palette.buttonText: langBtn.hovered ? "#ffffff" : cAccent
                onClicked: langMenu.open()
                Menu {
                    id: langMenu
                    MenuItem { text: "简体中文"; checkable: true; checked: root.currentLang === "zh_CN"; onTriggered: root.currentLang = "zh_CN" }
                    MenuItem { text: "繁體中文"; checkable: true; checked: root.currentLang === "zh_TW"; onTriggered: root.currentLang = "zh_TW" }
                    MenuItem { text: "English"; checkable: true; checked: root.currentLang === "en"; onTriggered: root.currentLang = "en" }
                    MenuItem { text: "日本語"; checkable: true; checked: root.currentLang === "ja"; onTriggered: root.currentLang = "ja" }
                }
            }
            // 夜晚模式切换（月亮=夜晚激活 / 太阳=白天）
            Button {
                id: darkBtn; text: root.isDark ? "🌙" : "☀️"; flat: true
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#80000000"; shadowBlur: 0.4; shadowVerticalOffset: 2 }
                background: Rectangle { color: darkBtn.hovered ? cAccent : (root.isDark ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.3) : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12)); radius: 8; border.color: darkBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4); border.width: 1; implicitHeight: 32; implicitWidth: 36; Behavior on color { ColorAnimation { duration: 150 } } }
                palette.buttonText: darkBtn.hovered ? "#ffffff" : cAccent
                onClicked: {
                    if (!root.isDark) {
                        // 进入黑夜模式：记录当前主题，custom 主题切到 blue（custom 背景色与暗色不兼容）
                        root.lastTheme = root.currentTheme;
                        root.isDark = true;
                        if (root.currentTheme === "custom") root.currentTheme = "blue";
                    } else {
                        // 退出黑夜模式：恢复之前的主题
                        root.isDark = false;
                        root.currentTheme = root.lastTheme;
                    }
                }
            }
            Button {
                id: clockBtn; text: "🕐"; flat: true
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#80000000"; shadowBlur: 0.4; shadowVerticalOffset: 2 }
                background: Rectangle { color: clockBtn.hovered ? cAccent : (clockVisible ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.3) : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12)); radius: 8; border.color: clockBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4); border.width: 1; implicitHeight: 32; implicitWidth: 36; Behavior on color { ColorAnimation { duration: 150 } } }
                palette.buttonText: clockBtn.hovered ? "#ffffff" : cAccent
                onClicked: clockVisible = !clockVisible
            }
            Button {
                id: appearanceBtn; text: "👕"; flat: true
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#80000000"; shadowBlur: 0.4; shadowVerticalOffset: 2 }
                background: Rectangle { color: appearanceBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12); radius: 8; border.color: appearanceBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4); border.width: 1; implicitHeight: 32; implicitWidth: 36; Behavior on color { ColorAnimation { duration: 150 } } }
                palette.buttonText: appearanceBtn.hovered ? "#ffffff" : cAccent
                onClicked: appearanceDialog.show()
            }
            Button {
                id: fileBtn; text: "📁"; flat: true
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#80000000"; shadowBlur: 0.4; shadowVerticalOffset: 2 }
                background: Rectangle { color: fileBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12); radius: 8; border.color: fileBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4); border.width: 1; implicitHeight: 32; implicitWidth: 36; Behavior on color { ColorAnimation { duration: 150 } } }
                palette.buttonText: fileBtn.hovered ? "#ffffff" : cAccent
                onClicked: fileDialog.show()
            }
            // 窗口控制按钮（最小化/最大化/关闭）
            Button {
                id: minBtn
                text: "—"; flat: true
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#80000000"; shadowBlur: 0.4; shadowVerticalOffset: 2 }
                background: Rectangle { color: minBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12); radius: 8; border.color: minBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4); border.width: 1; implicitHeight: 32; implicitWidth: 36; Behavior on color { ColorAnimation { duration: 150 } } }
                palette.buttonText: minBtn.hovered ? "#ffffff" : cAccent
                onClicked: root.showMinimized()
            }
            Button {
                id: maxBtn
                text: root.visibility === Window.Maximized ? "❐" : "☐"; flat: true
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#80000000"; shadowBlur: 0.4; shadowVerticalOffset: 2 }
                background: Rectangle { color: maxBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12); radius: 8; border.color: maxBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4); border.width: 1; implicitHeight: 32; implicitWidth: 36; Behavior on color { ColorAnimation { duration: 150 } } }
                palette.buttonText: maxBtn.hovered ? "#ffffff" : cAccent
                onClicked: root.visibility === Window.Maximized ? root.showNormal() : root.showMaximized()
            }
            Button {
                id: closeBtn
                text: "✕"; flat: true
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#80000000"; shadowBlur: 0.4; shadowVerticalOffset: 2 }
                background: Rectangle { color: closeBtn.hovered ? "#ff4444" : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12); radius: 8; border.color: closeBtn.hovered ? "#ff4444" : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4); border.width: 1; implicitHeight: 32; implicitWidth: 36; Behavior on color { ColorAnimation { duration: 150 } } }
                palette.buttonText: closeBtn.hovered ? "#ffffff" : cAccent
                onClicked: root.close()
            }
        }
    }

    // ===== 主页面可滚动区域（锚定 toolbar.bottom，不与时钟栏重叠）=====
    Flickable {
        id: mainScroll
        parent: bgRect
        anchors.top: toolbar.bottom; anchors.left: parent.left; anchors.right: parent.right
        // 底部留出空间给视频声音模块（仅视频背景时显示）
        anchors.bottom: videoSoundBar.visible ? videoSoundBar.top : parent.bottom
        clip: true; contentWidth: width; contentHeight: mainContentCol.height + 20
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: mainContentCol
            width: parent.width - 24; x: 12; spacing: 8; topPadding: 8

    // ===== 时间显示区块 =====
    Rectangle {
        id: timeBlock
        width: parent.width
        height: clockVisible ? 72 : 0; visible: clockVisible
        color: Qt.rgba(cCard.r, cCard.g, cCard.b, 0.7); radius: 8
        Column {
            anchors.centerIn: parent; spacing: 2
            Label {
                id: clockLabel
                text: "00:00:00"
                font.pixelSize: 28; font.bold: true; color: cAccent
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Label {
                id: dateLabel
                text: ""
                font.pixelSize: 13; color: cSub
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
        Timer {
            interval: 1000; running: clockVisible; repeat: true; triggeredOnStart: true
            onTriggered: {
                var d = new Date();
                var hh = ("0" + d.getHours()).slice(-2);
                var mm = ("0" + d.getMinutes()).slice(-2);
                var ss = ("0" + d.getSeconds()).slice(-2);
                clockLabel.text = hh + ":" + mm + ":" + ss;
                var y = d.getFullYear(), mo = ("0" + (d.getMonth() + 1)).slice(-2), da = ("0" + d.getDate()).slice(-2);
                // 日期格式：中/日用"年月日 星期 农历"，英文用"Weekday, Month Day, Year"（不显示农历）
                if (root.currentLang === "en") {
                    dateLabel.text = root.getWeekday(d) + ", " + Qt.formatDate(d, "MMMM d, yyyy");
                } else {
                    dateLabel.text = y + tt("yearStr") + mo + tt("monthStr") + da + tt("dayStr") + "  " + root.getWeekday(d) + "  " + tt("lunarPrefix") + root.getLunarDate(d);
                }
            }
        }
    }

    // ===== 搜索 + 统计栏区块 =====
    Rectangle {
        id: searchStatsCard
        width: parent.width
        color: Qt.rgba(cCard.r, cCard.g, cCard.b, 0.7); radius: 8
        height: searchCol.height + 16
        Column {
            id: searchCol
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8; spacing: 8
            TextField {
                id: searchField
                width: parent.width
                placeholderText: tt("search"); onTextChanged: reloadList()
                background: InputBg {}
            }
            Row {
                id: statsBar
                width: parent.width; spacing: 8
                Repeater {
                    model: [
                        { labelKey: "totalGames", prop: "totalCount", accent: "#7c5cff", status: "" },
                        { labelKey: "todo", prop: "todoCount", accent: "#ffb84d", status: "待玩" },
                        { labelKey: "playing", prop: "playingCount", accent: "#4d9fff", status: "进行中" },
                        { labelKey: "done", prop: "doneCount", accent: "#5bd06d", status: "已完成" }
                    ]
                    delegate: Rectangle {
                        id: statBtn
                        width: (statsBar.width - 8 * 3) / 4; height: 56; radius: 8
                        // 选中态：cAccent 0.75；hover 态：cCard 加 cAccent 0.18 着色；默认：cCard 0.7
                        color: root.statusFilter === modelData.status
                            ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.75)
                            : (statHover.containsMouse ? Qt.rgba(cCard.r + (cAccent.r - cCard.r) * 0.18, cCard.g + (cAccent.g - cCard.g) * 0.18, cCard.b + (cAccent.b - cCard.b) * 0.18, 0.9)
                                : Qt.rgba(cCard.r, cCard.g, cCard.b, 0.7))
                        border.color: root.statusFilter === modelData.status ? cAccent : (statHover.containsMouse ? cAccent : cBorder); border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Column { anchors.centerIn: parent; spacing: 2
                            Label { text: tt(modelData.labelKey); font.pixelSize: 11; color: root.statusFilter === modelData.status ? "#ffffff" : cSub; anchors.horizontalCenter: parent.horizontalCenter }
                            Label { text: root[modelData.prop]; font.bold: true; font.pixelSize: 18; color: root.statusFilter === modelData.status ? "#ffffff" : cText; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                        MouseArea {
                            id: statHover
                            anchors.fill: parent
                            enabled: modelData.status !== "__none__"
                            hoverEnabled: true   // 启用 hover 检测，containsMouse 才会更新
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: { if (modelData.status === "__none__") return; root.statusFilter = (root.statusFilter === modelData.status) ? "" : modelData.status; reloadList(); }
                        }
                    }
                }
            }
        }
    }

    // ===== 排序选择栏 =====
    Rectangle {
        id: sortBar
        width: parent.width
        height: 40; color: Qt.rgba(cCard.r, cCard.g, cCard.b, 0.7); radius: 8
        Row {
            anchors.fill: parent; anchors.margins: 8; spacing: 8; anchors.verticalCenter: parent.verticalCenter
            Label { text: tt("sort"); color: cSub; font.pixelSize: 13 }
            Button {
                text: tt("sortDate"); flat: true
                background: Rectangle { color: root.sortBy === "date" ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.2) : "transparent"; radius: 6; border.color: root.sortBy === "date" ? cAccent : "transparent"; border.width: 1; implicitHeight: 28 }
                palette.buttonText: root.sortBy === "date" ? cAccent : cText
                onClicked: { root.sortBy = "date"; reloadList(); }
            }
            Button {
                text: tt("sortName"); flat: true
                background: Rectangle { color: root.sortBy === "name" ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.2) : "transparent"; radius: 6; border.color: root.sortBy === "name" ? cAccent : "transparent"; border.width: 1; implicitHeight: 28 }
                palette.buttonText: root.sortBy === "name" ? cAccent : cText
                onClicked: { root.sortBy = "name"; reloadList(); }
            }
            Button {
                text: tt("sortRating"); flat: true
                background: Rectangle { color: root.sortBy === "rating" ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.2) : "transparent"; radius: 6; border.color: root.sortBy === "rating" ? cAccent : "transparent"; border.width: 1; implicitHeight: 28 }
                palette.buttonText: root.sortBy === "rating" ? cAccent : cText
                onClicked: { root.sortBy = "rating"; reloadList(); }
            }
        }
    }

    // ===== 添加按钮 + 饼图区块 =====
    Rectangle {
        id: addPieCard
        width: parent.width
        height: 180; color: Qt.rgba(cCard.r, cCard.g, cCard.b, 0.7); radius: 8
        Rectangle {
            id: addBar
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.margins: 8
            width: parent.width - 200 - 16
            color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12); radius: 8; border.color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4); border.width: 1
            Button {
                text: tt("add"); anchors.fill: parent; anchors.margins: 2; flat: true
                palette.buttonText: cAccent
                background: Rectangle { color: "transparent"; radius: 6 }
                onClicked: addDialog.show()
            }
        }
        ChartView {
            id: mainChart
            anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.margins: 4
            width: 200; antialiasing: true
            backgroundColor: "transparent"; plotAreaColor: "transparent"
            legend.visible: true; legend.alignment: Qt.AlignRight; legend.labelColor: cText; legend.font.pixelSize: 9
            PieSeries {
                id: mainPieSeries; size: 0.8
            }
        }
    }

    // ===== 游戏列表 =====
    ListView {
        id: listView
        width: parent.width; height: contentHeight
        clip: true; model: gameListModel; spacing: 8
        interactive: false
        delegate: Rectangle {
            width: listView.width; height: 56; radius: 8
            color: Qt.rgba(cCard.r, cCard.g, cCard.b, 0.75); border.color: cBorder; border.width: 1
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: gameDetailDialog.openWith(gameId, gameName, gameCover, gameTypes, gameRating, gameStatus, gameStartDate, gameFinishDate, gameNotes)
            }
            Item {
                id: coverItem
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 8; width: 40; height: 44
                Image { anchors.fill: parent; source: gameCover.length > 0 ? "file:///" + gameCover : ""; fillMode: Image.PreserveAspectCrop; visible: gameCover.length > 0 }
                Rectangle { anchors.fill: parent; color: Qt.rgba(cBorder.r, cBorder.g, cBorder.b, 0.6); visible: gameCover.length === 0; radius: 4; Text { anchors.centerIn: parent; text: tt("noCover"); color: cSub; font.pixelSize: 9 } }
            }
            Column {
                anchors.left: coverItem.right; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 10; anchors.right: ratingBox.left; anchors.rightMargin: 8; spacing: 3
                Text { width: parent.width; text: gameName; font.bold: true; font.pixelSize: 14; color: cText; elide: Text.ElideRight }
                Text { width: parent.width; text: formatTagsWithStatus(gameTypes, gameStatus); font.pixelSize: 12; color: cSub; elide: Text.ElideRight }
            }
            // 评分显示（最右边，大字体，垂直居中）
            Item {
                id: ratingBox
                width: 48; height: parent.height
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.rightMargin: 12
                Text {
                    anchors.centerIn: parent
                    text: gameRating.toFixed(1); font.bold: true; font.pixelSize: 20; color: "#ffc107"
                }
            }
        }
        Label {
            anchors.centerIn: parent; visible: listView.count === 0
            text: searchField.text.length > 0 ? tt("noMatchGame") : tt("emptyGameList")
            horizontalAlignment: Text.AlignHCenter; color: cSub
        }
    }
        }   // Column

        // 自动隐藏滚动条
        ScrollBar.vertical: ScrollBar {
            id: mainScrollSB; policy: ScrollBar.AsNeeded; width: 10; interactive: true
            opacity: 0; Behavior on opacity { NumberAnimation { duration: 200 } }
            contentItem: Rectangle { radius: 5; color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.7) }
            onHoveredChanged: { if (hovered) { opacity = 1.0; sbHideTimer.stop() } else { sbHideTimer.restart() } }
            onPressedChanged: { if (pressed) { opacity = 1.0; sbHideTimer.stop() } else { sbHideTimer.restart() } }
        }
        Timer { id: sbHideTimer; interval: 800; onTriggered: { if (!mainScrollSB.hovered && !mainScrollSB.pressed) mainScrollSB.opacity = 0.0 } }
        onContentYChanged: { mainScrollSB.opacity = 1.0; sbHideTimer.restart() }
    }   // Flickable

    // ===== 视频背景工具模块（仅视频背景时显示，固定在主页面底部，透明背景无边框）=====
    // 布局：进度条水平居中 + 右侧倍速/声音按钮 Row（用户第87轮选定方案B）
    // 播放/暂停按钮：32×32 正方形；声音控制：喇叭图标按钮 + Popup 浮动面板（含静音+音量条）
    Rectangle {
        id: videoSoundBar
        parent: bgRect
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.margins: 12
        height: 44
        visible: root.bgImagePath.length > 0 && isVideoFile(root.bgImagePath)
        color: "transparent"; border.width: 0
        radius: 8

        // 中间区域：进度条水平居中（含 hover 时间标签）
        Item {
            id: videoProgressWrap
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: videoProgress.width; height: videoProgress.height
            RoundSlider {
                id: videoProgress
                from: 0
                to: bgMediaPlayer.duration > 0 ? bgMediaPlayer.duration : 1
                // 进度条宽度：工具框宽度减去右侧按钮组宽度 + 间距，限制最大 400 最小 180
                width: Math.max(180, Math.min(400, videoSoundBar.width - rightCtrlRow.implicitWidth - 40))
                enabled: bgMediaPlayer.duration > 0
                Binding on value {
                    value: bgMediaPlayer.position
                    when: !videoProgress.pressed
                    restoreMode: Binding.RestoreBinding
                }
                onMoved: bgMediaPlayer.position = value
            }
            HoverHandler {
                id: videoProgressHover
                target: videoProgress
            }
            // 时间标签（浮在进度条上方，hover 或拖动时显示）
            Rectangle {
                id: videoTimeLabel
                visible: (videoProgressHover.hovered || videoProgress.pressed) && bgMediaPlayer.duration > 0
                anchors.bottom: videoProgress.top
                anchors.bottomMargin: 4
                anchors.horizontalCenter: videoProgress.horizontalCenter
                color: "#cc000000"
                radius: 4
                width: timeLabelText.implicitWidth + 12
                height: timeLabelText.implicitHeight + 4
                Label {
                    id: timeLabelText
                    anchors.centerIn: parent
                    text: formatTime(videoProgress.value) + " / " + formatTime(bgMediaPlayer.duration)
                    color: "#ffffff"
                    font.pixelSize: 11
                }
            }
        }

        // 按钮组：播放/暂停（正方形）+ 倍速 + 声音（紧贴进度条右侧，随进度条居中而靠近中间）
        Row {
            id: rightCtrlRow
            anchors.left: videoProgressWrap.right   // 锚定进度条右侧（用户要求按钮往中间靠，紧贴进度条）
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // 播放/暂停按钮（32×32 正方形）
            Button {
                id: videoPlayBtn
                text: root.bgVideoPaused ? "▶" : "■"
                flat: true
                background: Rectangle {
                    color: videoPlayBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.18)
                    radius: 8; border.color: videoPlayBtn.hovered ? cAccent : cAccent; border.width: 1
                    implicitWidth: 32; implicitHeight: 32   // 正方形固定尺寸
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                palette.buttonText: videoPlayBtn.hovered ? "#ffffff" : cAccent
                onClicked: root.bgVideoPaused = !root.bgVideoPaused
            }

            // 倍速按钮（文字"倍速"+当前值，点击 Menu 选择 0.25x-3.0x）
            Button {
                id: videoRateBtn
                text: tt("videoRate") + " " + root.bgVideoRate + "x"
                flat: true
                background: Rectangle {
                    color: videoRateBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.18)
                    radius: 8; border.color: videoRateBtn.hovered ? cAccent : cAccent; border.width: 1; implicitHeight: 32
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                palette.buttonText: videoRateBtn.hovered ? "#ffffff" : cAccent
                onClicked: videoRateMenu.open()
                Menu {
                    id: videoRateMenu
                    MenuItem { text: "0.25x"; checkable: true; checked: Math.abs(root.bgVideoRate - 0.25) < 0.01; onTriggered: root.bgVideoRate = 0.25 }
                    MenuItem { text: "0.5x";  checkable: true; checked: Math.abs(root.bgVideoRate - 0.5)  < 0.01; onTriggered: root.bgVideoRate = 0.5  }
                    MenuItem { text: "0.75x"; checkable: true; checked: Math.abs(root.bgVideoRate - 0.75) < 0.01; onTriggered: root.bgVideoRate = 0.75 }
                    MenuItem { text: "1.0x";  checkable: true; checked: Math.abs(root.bgVideoRate - 1.0)  < 0.01; onTriggered: root.bgVideoRate = 1.0  }
                    MenuItem { text: "1.25x"; checkable: true; checked: Math.abs(root.bgVideoRate - 1.25) < 0.01; onTriggered: root.bgVideoRate = 1.25 }
                    MenuItem { text: "1.5x";  checkable: true; checked: Math.abs(root.bgVideoRate - 1.5)  < 0.01; onTriggered: root.bgVideoRate = 1.5  }
                    MenuItem { text: "2.0x";  checkable: true; checked: Math.abs(root.bgVideoRate - 2.0)  < 0.01; onTriggered: root.bgVideoRate = 2.0  }
                    MenuItem { text: "3.0x";  checkable: true; checked: Math.abs(root.bgVideoRate - 3.0)  < 0.01; onTriggered: root.bgVideoRate = 3.0  }
                }
            }

            // 声音控制按钮（仅喇叭图标 🔊/🔇，点击弹出 Popup 浮动面板含静音+竖直音量条）
            Button {
                id: videoSoundBtn
                text: root.bgVideoMuted ? "🔇" : "🔊"
                flat: true
                background: Rectangle {
                    color: videoSoundBtn.hovered ? cAccent : (root.bgVideoMuted ? Qt.rgba(cSub.r, cSub.g, cSub.b, 0.18) : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.18))
                    radius: 8; border.color: videoSoundBtn.hovered ? cAccent : (root.bgVideoMuted ? cSub : cAccent); border.width: 1
                    implicitWidth: 32; implicitHeight: 32   // 与播放暂停按钮一致正方形
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                palette.buttonText: videoSoundBtn.hovered ? "#ffffff" : (root.bgVideoMuted ? cSub : cAccent)
                onClicked: videoSoundPopup.open()

                // Popup 浮动面板（竖直布局，类似 Windows 任务栏声音弹窗）
                Popup {
                    id: videoSoundPopup
                    x: (videoSoundBtn.width - width) / 2   // 水平居中于按钮
                    y: -height - 8   // 显示在按钮上方
                    width: 80; height: 220   // 竖直长方形面板
                    modal: false; dim: false
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                    background: Rectangle {
                        color: cCard; radius: 8; border.color: cBorder; border.width: 1
                        layer.enabled: true
                        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#80000000"; shadowBlur: 0.5; shadowVerticalOffset: 2 }
                    }
                    padding: 10
                    contentItem: Column {
                        spacing: 8
                        // 顶部：静音按钮（喇叭图标，点击切换静音）
                        Button {
                            id: popupMuteBtn
                            text: root.bgVideoMuted ? "🔇" : "🔊"
                            flat: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            background: Rectangle {
                                color: popupMuteBtn.hovered ? cAccent : "transparent"
                                radius: 6; border.color: popupMuteBtn.hovered ? cAccent : "transparent"; border.width: 1
                                implicitWidth: 36; implicitHeight: 32
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            palette.buttonText: popupMuteBtn.hovered ? "#ffffff" : (root.bgVideoMuted ? cSub : cAccent)
                            onClicked: root.bgVideoMuted = !root.bgVideoMuted
                        }
                        // 音量值标签
                        Label {
                            text: Math.round(root.bgVideoVolume * 100) + "%"
                            color: cText; font.pixelSize: 11
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        // 竖直音量滑块（用原生 Slider + orientation:Qt.Vertical，RoundSlider 不支持竖直）
                        // from:0.0 to:1.0 正常方向：value=0 在底部=音量0，value=1 在顶部=音量最大
                        // 往上拖 handle=音量变大，往下拖=音量变小（符合 Windows 任务栏音量条习惯）
                        // 注意：竖直 Slider 的 visualPosition 方向不确定，改用 value 直接计算位置最可靠
                        Slider {
                            id: popupVolumeSlider
                            orientation: Qt.Vertical
                            from: 0.0; to: 1.0; value: root.bgVideoVolume
                            onMoved: root.bgVideoVolume = value
                            width: 32; height: 120   // 显式宽高避免在 Column 中尺寸为 0
                            anchors.horizontalCenter: parent.horizontalCenter
                            enabled: !root.bgVideoMuted
                            opacity: root.bgVideoMuted ? 0.5 : 1.0
                            // 自定义样式与 RoundSlider 视觉一致（竖直版）
                            background: Rectangle {
                                implicitWidth: 32; implicitHeight: 120
                                x: popupVolumeSlider.leftPadding + popupVolumeSlider.availableWidth / 2 - 2
                                y: popupVolumeSlider.topPadding
                                width: 4; height: popupVolumeSlider.availableHeight; radius: 2
                                color: Qt.rgba(root.cBorder.r, root.cBorder.g, root.cBorder.b, 0.6)
                                Rectangle {
                                    // 已选区域：从底部到 handle（Windows 音量条风格：handle 下方为已选区域）
                                    // 用 value 计算：value=0 时 y=height height=0（空），value=1 时 y=0 height=满（整条）
                                    y: (1 - popupVolumeSlider.value) * parent.height
                                    height: popupVolumeSlider.value * parent.height
                                    width: parent.width; radius: 2
                                    color: root.cAccent
                                }
                            }
                            handle: Rectangle {
                                x: popupVolumeSlider.leftPadding + popupVolumeSlider.availableWidth / 2 - width / 2
                                // 用 value 计算：value=0 时 y 在底部，value=1 时 y 在顶部
                                y: popupVolumeSlider.topPadding + (1 - popupVolumeSlider.value) * (popupVolumeSlider.availableHeight - height)
                                width: 16; height: 16; radius: 8
                                color: popupVolumeSlider.pressed ? Qt.lighter(root.cAccent, 1.2) : root.cAccent
                                border.color: "#ffffff"; border.width: 2
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }
                        }
                    }
                }
            }
        }
    }

    // ===== 添加游戏弹窗 =====
    Window {
        id: addDialog
        title: tt("addTitle")
        modality: Qt.WindowModal
        flags: Qt.FramelessWindowHint | Qt.Window
        width: 400; height: 520
        minimumWidth: 380; minimumHeight: 480
        color: "transparent"
        x: root.x + (root.width - width) / 2
        y: root.y + (root.height - height) / 2
        palette.window: cCard; palette.windowText: cText; palette.text: cText; palette.button: cCard; palette.buttonText: cText; palette.base: cInput; palette.placeholderText: cSub; palette.highlight: cAccent; palette.highlightedText: "#ffffff"

        // 已选 TAG 列表（tagDialog 保存时写回此属性，Flow+Repeater 自动刷新显示）
        property var selectedTags: []
        property string startDateValue: ""
        property string finishDateValue: ""
        // 关闭对话框时清空已选 TAG 和表单（避免下次打开残留上次选择）
        onClosing: { selectedTags = []; nameField.text = ""; notesField.text = ""; addCoverPath.text = ""; startDateValue = ""; finishDateValue = ""; addStartDateBtn.text = tt("selectDate"); addFinishDateBtn.text = tt("selectDate") }

        Rectangle { anchors.fill: parent; radius: 8; color: root.cBg }
        FramelessDragBar { dialogWindow: addDialog }
        Flickable {
            anchors.fill: parent; anchors.margins: 12; anchors.topMargin: 38; clip: true; contentWidth: width; contentHeight: addCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: MainSB {}
            ColumnLayout { id: addCol; width: parent.width; spacing: 10
                TextField { id: nameField; Layout.fillWidth: true; placeholderText: tt("name"); background: InputBg {} }
                // 游戏 TAG 区域（可视化按钮 + 选 TAG 按钮）
                ColumnLayout { Layout.fillWidth: true; spacing: 6
                    // 已选 TAG 按钮列表（Flow 自动换行，每个 tag 是圆角小按钮带 ✕ 删除）
                    Flow {
                        id: addTagFlow; Layout.fillWidth: true; spacing: 6
                        visible: addDialog.selectedTags.length > 0
                        Repeater {
                            model: addDialog.selectedTags
                            delegate: Rectangle {
                                width: addTagText.implicitWidth + 28; height: 24; radius: 12
                                color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15)
                                border.color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4); border.width: 1
                                Text { id: addTagText; anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: modelData; color: cAccent; font.pixelSize: 11 }
                                // ✕ 删除按钮（直接在添加页删除 tag，无需打开 tagDialog）
                                Rectangle {
                                    anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter
                                    width: 14; height: 14; radius: 7
                                    color: addTagDelMA.containsMouse ? "#ff4444" : "transparent"
                                    border.color: addTagDelMA.containsMouse ? "#ff4444" : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4); border.width: 1
                                    Text { anchors.centerIn: parent; text: "✕"; color: addTagDelMA.containsMouse ? "#ffffff" : cAccent; font.pixelSize: 8 }
                                    MouseArea { id: addTagDelMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { var l = addDialog.selectedTags.slice(); l.splice(index, 1); addDialog.selectedTags = l } }
                                }
                            }
                        }
                    }
                    // 空占位提示（无 tag 时）+ 选 TAG 按钮
                    Row { Layout.fillWidth: true; spacing: 6
                        Label {
                            text: addDialog.selectedTags.length === 0 ? tt("noTagHint") : ""
                            color: cSub; font.pixelSize: 11
                            verticalAlignment: Text.AlignVCenter
                            visible: addDialog.selectedTags.length === 0
                            Layout.fillWidth: true
                        }
                        Button {
                            id: addSelectTagBtn
                            text: "+ " + tt("selectTag"); flat: true; implicitHeight: 28; implicitWidth: 90
                            background: Rectangle {
                                color: addSelectTagBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.2)
                                radius: 4; border.color: cAccent; border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            palette.buttonText: addSelectTagBtn.hovered ? "#ffffff" : cAccent; font.pixelSize: 11
                            onClicked: tagDialog.openWith(addDialog)
                        }
                    }
                }
                Row { Layout.fillWidth: true; spacing: 4; Label { text: tt("rating"); anchors.verticalCenter: parent.verticalCenter; color: cSub } StarInput { id: ratingField } }
                ComboBox { id: statusField; Layout.fillWidth: true; model: root.currentLang.length >= 0 ? [tt("todo"), tt("playing"), tt("done")] : []; background: InputBg {} }
                ColumnLayout { Layout.fillWidth: true; spacing: 6
                    Label { text: tt("playDate"); color: cSub; font.pixelSize: 13 }
                    Row { Layout.fillWidth: true; spacing: 8
                        Button {
                            id: addStartDateBtn; text: tt("selectDate"); flat: true; implicitHeight: 30; implicitWidth: 120
                            background: Rectangle { color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1); radius: 4; border.color: cBorder; border.width: 1 }
                            palette.buttonText: cText; font.pixelSize: 12
                            onClicked: dateSelector.openWith("addStart", addDialog.startDateValue)
                        }
                        Label { text: tt("toDate"); anchors.verticalCenter: parent.verticalCenter; color: cSub; font.pixelSize: 13 }
                        Button {
                            id: addFinishDateBtn; text: tt("selectDate"); flat: true; implicitHeight: 30; implicitWidth: 120
                            background: Rectangle { color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1); radius: 4; border.color: cBorder; border.width: 1 }
                            palette.buttonText: cText; font.pixelSize: 12
                            onClicked: dateSelector.openWith("addFinish", addDialog.finishDateValue)
                        }
                    }
                }
                Row { Layout.fillWidth: true; spacing: 8
                    BtnGhost { text: tt("selectCover"); onClicked: addCoverDialog.open() }
                    Image { width: 56; height: 76; source: addCoverPath.text.length > 0 ? "file:///" + addCoverPath.text : ""; fillMode: Image.PreserveAspectCrop; visible: addCoverPath.text.length > 0 }
                }
                TextField { id: addCoverPath; visible: false }
                TextArea { id: notesField; Layout.fillWidth: true; placeholderText: tt("notes"); wrapMode: TextArea.Wrap; height: 70; font.pixelSize: 13; background: InputBg {} }
                BtnSave {
                    Layout.alignment: Qt.AlignHCenter
                    background: Rectangle { color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.75); radius: 8; implicitWidth: 80; implicitHeight: 34 }
                    onClicked: {
                        if (nameField.text.trim() === "") { warn(tt("warnName")); return; }
                        // 直接读取 addDialog.selectedTags 数组（无需解析字符串）
                        var types = addDialog.selectedTags.slice()
                        if (types.length === 0) { warn(tt("warnType")); return; }
                        var r = parseFloat(ratingField.field.text);
                        if (isNaN(r) || r < 0 || r > 10) { warn(tt("warnRating")); return; }
                        dbManager.addGame(nameField.text, types, r, root.statusKeys[statusField.currentIndex], 0, addDialog.startDateValue, addDialog.finishDateValue, notesField.text, addCoverPath.text);
                        reloadList(); refreshStats(); addDialog.close();   // onClosing 会自动清空 selectedTags 和表单
                    }
                }
            }
        }
    }
    FileDialog { id: addCoverDialog; title: tt("selectCoverPic"); nameFilters: ["图片文件 (*.jpg *.jpeg *.png *.bmp *.webp)"]; onAccepted: addCoverPath.text = dbManager.importCover(urlToPath(currentFile)) }

    // ===== 编辑对话框 =====
    Window {
        id: editDialog
        title: tt("editTitle")
        modality: Qt.WindowModal
        transientParent: gameDetailDialog
        flags: Qt.FramelessWindowHint | Qt.Window
        width: 400; height: 520
        minimumWidth: 380; minimumHeight: 480
        color: "transparent"
        x: root.x + (root.width - width) / 2
        y: root.y + (root.height - height) / 2
        palette.window: cCard; palette.windowText: cText; palette.text: cText; palette.button: cCard; palette.buttonText: cText; palette.base: cInput; palette.placeholderText: cSub; palette.highlight: cAccent; palette.highlightedText: "#ffffff"

        // 已选 TAG 列表（tagDialog 保存时写回此属性，Flow+Repeater 自动刷新显示）
        property var selectedTags: []
        property string startDateValue: ""
        property string finishDateValue: ""
        // 编辑窗打开时从详情窗初始化日期值与按钮显示
        onVisibleChanged: {
            if (visible) {
                startDateValue = gameDetailDialog.detailGameStartDate
                finishDateValue = gameDetailDialog.detailGameFinishDate
                editStartDateBtn.text = startDateValue.length > 0 ? root.formatDate(startDateValue) : root.tt("selectDate")
                editFinishDateBtn.text = finishDateValue.length > 0 ? root.formatDate(finishDateValue) : root.tt("selectDate")
            }
        }

        Rectangle { anchors.fill: parent; radius: 8; color: root.cBg }
        FramelessDragBar { dialogWindow: editDialog }
        Flickable {
            anchors.fill: parent; anchors.margins: 12; anchors.topMargin: 38; clip: true; contentWidth: width; contentHeight: editCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: MainSB {}
            ColumnLayout { id: editCol; width: parent.width; spacing: 10
                TextField { id: editNameField; Layout.fillWidth: true; placeholderText: tt("name"); background: InputBg {} }
                // 游戏 TAG 区域（可视化按钮 + 选 TAG 按钮）
                ColumnLayout { Layout.fillWidth: true; spacing: 6
                    // 已选 TAG 按钮列表（Flow 自动换行，每个 tag 是圆角小按钮带 ✕ 删除）
                    Flow {
                        id: editTagFlow; Layout.fillWidth: true; spacing: 6
                        visible: editDialog.selectedTags.length > 0
                        Repeater {
                            model: editDialog.selectedTags
                            delegate: Rectangle {
                                width: editTagText.implicitWidth + 28; height: 24; radius: 12
                                color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15)
                                border.color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4); border.width: 1
                                Text { id: editTagText; anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: modelData; color: cAccent; font.pixelSize: 11 }
                                // ✕ 删除按钮（直接在编辑页删除 tag，无需打开 tagDialog）
                                Rectangle {
                                    anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter
                                    width: 14; height: 14; radius: 7
                                    color: editTagDelMA.containsMouse ? "#ff4444" : "transparent"
                                    border.color: editTagDelMA.containsMouse ? "#ff4444" : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4); border.width: 1
                                    Text { anchors.centerIn: parent; text: "✕"; color: editTagDelMA.containsMouse ? "#ffffff" : cAccent; font.pixelSize: 8 }
                                    MouseArea { id: editTagDelMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { var l = editDialog.selectedTags.slice(); l.splice(index, 1); editDialog.selectedTags = l } }
                                }
                            }
                        }
                    }
                    // 空占位提示（无 tag 时）+ 选 TAG 按钮
                    Row { Layout.fillWidth: true; spacing: 6
                        Label {
                            text: editDialog.selectedTags.length === 0 ? tt("noTagHint") : ""
                            color: cSub; font.pixelSize: 11
                            verticalAlignment: Text.AlignVCenter
                            visible: editDialog.selectedTags.length === 0
                            Layout.fillWidth: true
                        }
                        Button {
                            id: editSelectTagBtn
                            text: "+ " + tt("selectTag"); flat: true; implicitHeight: 28; implicitWidth: 90
                            background: Rectangle {
                                color: editSelectTagBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.2)
                                radius: 4; border.color: cAccent; border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            palette.buttonText: editSelectTagBtn.hovered ? "#ffffff" : cAccent; font.pixelSize: 11
                            onClicked: tagDialog.openWith(editDialog)
                        }
                    }
                }
                Row { Layout.fillWidth: true; spacing: 4; Label { text: tt("rating"); anchors.verticalCenter: parent.verticalCenter; color: cSub } StarInput { id: editRatingField } }
                ComboBox { id: editStatusField; Layout.fillWidth: true; model: root.currentLang.length >= 0 ? [tt("todo"), tt("playing"), tt("done")] : []; background: InputBg {} }
                ColumnLayout { Layout.fillWidth: true; spacing: 6
                    Label { text: tt("playDate"); color: cSub; font.pixelSize: 13 }
                    Row { Layout.fillWidth: true; spacing: 8
                        Button {
                            id: editStartDateBtn; text: tt("selectDate"); flat: true; implicitHeight: 30; implicitWidth: 120
                            background: Rectangle { color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1); radius: 4; border.color: cBorder; border.width: 1 }
                            palette.buttonText: cText; font.pixelSize: 12
                            onClicked: dateSelector.openWith("editStart", editDialog.startDateValue)
                        }
                        Label { text: tt("toDate"); anchors.verticalCenter: parent.verticalCenter; color: cSub; font.pixelSize: 13 }
                        Button {
                            id: editFinishDateBtn; text: tt("selectDate"); flat: true; implicitHeight: 30; implicitWidth: 120
                            background: Rectangle { color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1); radius: 4; border.color: cBorder; border.width: 1 }
                            palette.buttonText: cText; font.pixelSize: 12
                            onClicked: dateSelector.openWith("editFinish", editDialog.finishDateValue)
                        }
                    }
                }
                Row { Layout.fillWidth: true; spacing: 8
                    BtnGhost { text: tt("selectCover"); onClicked: editCoverDialog.open() }
                    BtnGhost { text: tt("editCover"); enabled: editCoverPath.text.length > 0; onClicked: cropDialog.openCover(editCoverPath.text) }
                    Image { width: 56; height: 76; source: editCoverPath.text.length > 0 ? "file:///" + editCoverPath.text : ""; fillMode: Image.PreserveAspectCrop; visible: editCoverPath.text.length > 0 }
                }
                TextField { id: editCoverPath; visible: false }
                TextArea { id: editNotesField; Layout.fillWidth: true; placeholderText: tt("notes"); wrapMode: TextArea.Wrap; height: 80; font.pixelSize: 13; background: InputBg {} }
                BtnSave { Layout.alignment: Qt.AlignHCenter; onClicked: {
                    if (editNameField.text.trim() === "") { warn(tt("warnName")); return; }
                    // 直接读取 editDialog.selectedTags 数组（无需解析字符串）
                    var types = editDialog.selectedTags.slice()
                    if (types.length === 0) { warn(tt("warnType")); return; }
                    var r = parseFloat(editRatingField.field.text);
                    if (isNaN(r) || r < 0 || r > 10) { warn(tt("warnRating")); return; }
                    dbManager.updateGame(editDialog.gameId, editNameField.text, types, r, root.statusKeys[editStatusField.currentIndex], 0, editDialog.startDateValue, editDialog.finishDateValue, editNotesField.text, editCoverPath.text);
                    // 更新详情窗的数据并返回详情窗（detailGameTypes 已改为 var 数组，直接赋值）
                    gameDetailDialog.detailGameName = editNameField.text;
                    gameDetailDialog.detailGameTypes = types;
                    gameDetailDialog.selectedTags = types.slice();   // 同步 selectedTags（保证 tagDialog 下次打开时读取最新值）
                    gameDetailDialog.detailGameRating = r;
                    gameDetailDialog.detailGameStatus = root.statusKeys[editStatusField.currentIndex];
                    gameDetailDialog.detailGameStartDate = editDialog.startDateValue;
                    gameDetailDialog.detailGameFinishDate = editDialog.finishDateValue;
                    gameDetailDialog.detailGameNotes = editNotesField.text;
                    gameDetailDialog.detailGameCover = editCoverPath.text;
                    editDialog.close(); reloadList(); refreshStats();
                    if (gameDetailDialog.visible) gameDetailDialog.requestActivate();
                }}
            }
        }
    }
    FileDialog { id: editCoverDialog; title: tt("selectCoverPic"); nameFilters: ["图片文件 (*.jpg *.jpeg *.png *.bmp *.webp)"]; onAccepted: editCoverPath.text = dbManager.importCover(urlToPath(currentFile)) }

    // ===== 删除确认（嵌套于游戏详情窗，Window+transientParent）=====
    Window {
        id: deleteDialog
        transientParent: gameDetailDialog
        flags: Qt.FramelessWindowHint | Qt.Window
        color: "transparent"
        title: tt("deleteTitle")
        width: 320; height: 180
        x: gameDetailDialog.x + Math.max(24, (gameDetailDialog.width - width) / 2)
        y: gameDetailDialog.y + Math.max(24, (gameDetailDialog.height - height) / 2)
        property int gameId: -1
        property string gameName: ""
        function openWith(gid, gname) { gameId = gid; gameName = gname; show() }
        onVisibleChanged: {
            if (!visible && gameDetailDialog.visible) gameDetailDialog.requestActivate()
        }
        Rectangle { anchors.fill: parent; radius: 8; color: root.cBg }
        FramelessDragBar { dialogWindow: deleteDialog }
        Column {
            anchors.fill: parent; anchors.margins: 16; anchors.topMargin: 38; spacing: 16
            Item { width: 1; height: 4 }
            Text {
                text: tt("deleteConfirm", deleteDialog.gameName)
                color: cText; font.pixelSize: 13
                wrapMode: Text.Wrap; width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }
            Row {
                spacing: 8; anchors.horizontalCenter: parent.horizontalCenter
                Button {
                    text: tt("cancelEdit"); flat: true; implicitHeight: 30; implicitWidth: 80
                    background: Rectangle { color: Qt.rgba(cText.r, cText.g, cText.b, 0.1); radius: 4; border.color: cBorder; border.width: 1 }
                    palette.buttonText: cSub; font.pixelSize: 11
                    onClicked: deleteDialog.hide()
                }
                Button {
                    text: tt("del"); flat: true; implicitHeight: 30; implicitWidth: 80
                    background: Rectangle { color: "#30ff4444"; radius: 4; border.color: "#ff4444"; border.width: 1 }
                    palette.buttonText: "#ff4444"; font.pixelSize: 11
                    onClicked: { gameDetailDialog.hide(); dbManager.deleteGame(deleteDialog.gameId); gameListModel.refresh(searchField.text); refreshStats(); deleteDialog.hide() }
                }
            }
        }
    }

    // ===== 游戏详情信息框（可缩放窗口）=====
    Window {
        id: gameDetailDialog
        title: tt("gameDetail")
        modality: Qt.WindowModal
        flags: Qt.FramelessWindowHint | Qt.Window
        width: 820; height: 580
        minimumWidth: 600; minimumHeight: 420
        color: "transparent"
        x: root.x + (root.width - width) / 2
        y: root.y + (root.height - height) / 2

        property int detailGameId: -1
        property string detailGameName: ""
        property string detailGameCover: ""
        property var detailGameTypes: []
        // selectedTags 用于 tagDialog 交互（与 detailGameTypes 双向同步：openWith 初始化、onTagsSaved 写回）
        property var selectedTags: []
        property double detailGameRating: 0
        property string detailGameStatus: ""
        property string detailGameStartDate: ""
        property string detailGameFinishDate: ""
        property string detailGameNotes: ""
        // 内联编辑状态（同时只能编辑一处）
        property bool editingName: false
        property bool editingNotes: false
        property bool editingRating: false

        // 互斥：开启新编辑前自动保存上一次编辑
        function commitCurrentEdit() {
            if (editingName) saveInlineName(nameEditField.text);
            if (editingNotes) saveInlineNotes(notesEditArea.text);
            if (editingRating) saveInlineRating(ratingEditField.text);
        }
        function startEditName() {
            commitCurrentEdit();
            nameEditField.text = detailGameName;
            editingName = true;
            nameEditField.forceActiveFocus();
        }
        function startEditNotes() {
            commitCurrentEdit();
            notesEditArea.text = detailGameNotes;
            editingNotes = true;
            notesEditArea.forceActiveFocus();
        }

        // 保存内联编辑的名称
        function saveInlineName(newName) {
            if (newName.trim().length === 0) { editingName = false; return }
            dbManager.updateGame(detailGameId, newName.trim(), detailGameTypes,
                detailGameRating, detailGameStatus, 0,
                detailGameStartDate, detailGameFinishDate, detailGameNotes, detailGameCover);
            detailGameName = newName.trim();
            editingName = false;
            gameListModel.refresh(searchField.text);
        }
        // 评分直接点击星星保存（无编辑态）
        function saveInlineRating(newRating) {
            var r = parseFloat(newRating);
            if (isNaN(r)) r = detailGameRating;   // 非数字时保持原值
            r = Math.max(0, Math.min(10, Math.round(r * 10) / 10));   // 限制 0.0-10.0，保留 1 位小数
            if (r !== detailGameRating) {
                dbManager.updateGame(detailGameId, detailGameName, detailGameTypes,
                    r, detailGameStatus, 0,
                    detailGameStartDate, detailGameFinishDate, detailGameNotes, detailGameCover);
                detailGameRating = r;
                gameListModel.refresh(searchField.text);
            }
            editingRating = false;
        }
        function startEditRating() {
            commitCurrentEdit();
            ratingEditField.text = detailGameRating.toFixed(1);
            editingRating = true;
            ratingEditField.forceActiveFocus();
            ratingEditField.selectAll();
        }
        // 保存内联编辑的类型（接受数组：直接赋值给 detailGameTypes，updateGame 接受 QStringList）
        function saveInlineTypes(newTypesArr) {
            commitCurrentEdit();
            dbManager.updateGame(detailGameId, detailGameName, newTypesArr,
                detailGameRating, detailGameStatus, 0,
                detailGameStartDate, detailGameFinishDate, detailGameNotes, detailGameCover);
            detailGameTypes = newTypesArr;
            // 同步 selectedTags（保证 detailGameTypes 与 selectedTags 始终一致，避免 tagDialog 读取旧值）
            selectedTags = newTypesArr.slice()
            gameListModel.refresh(searchField.text);
        }
        // tagDialog 保存回调：与 saveInlineTypes 等价（接受 tag 数组，同步 detailGameTypes + selectedTags + 持久化数据库 + 刷新列表）
        function onTagsSaved(tags) {
            saveInlineTypes(tags)
        }
        // 切换游戏状态（待玩→进行中→已完成→待玩）
        function cycleStatus() {
            commitCurrentEdit();
            var statuses = ["待玩", "进行中", "已完成"];
            var idx = statuses.indexOf(detailGameStatus);
            var next = statuses[(idx + 1) % 3];
            dbManager.updateGame(detailGameId, detailGameName, detailGameTypes,
                detailGameRating, next, 0,
                detailGameStartDate, detailGameFinishDate, detailGameNotes, detailGameCover);
            detailGameStatus = next;
            gameListModel.refresh(searchField.text);
            root.refreshStats();   // 状态改变后重新统计（待玩/进行中/已完成数量）
        }
        // 保存内联编辑的评价
        function saveInlineNotes(newNotes) {
            dbManager.updateGame(detailGameId, detailGameName, detailGameTypes,
                detailGameRating, detailGameStatus, 0,
                detailGameStartDate, detailGameFinishDate, newNotes, detailGameCover);
            detailGameNotes = newNotes;
            editingNotes = false;
        }
        // 更换封面（从文件选择→裁剪→保存）
        function changeCover() {
            commitCurrentEdit();
            coverPickerForDetail.open();
        }
        property var screenshots: []
        // 回忆模块全局播放参数（从数据库读取，供回忆编辑使用）
        property int ssInterval: 3000   // 轮播间隔（毫秒）
        property int ssFade: 800        // 淡入淡出时长（毫秒）
        property string memDisplayMode: "carousel"   // 展示模式：carousel(轮播，默认) / grid(网格)

        function loadScreenshotSettings() {
            var s = dbManager.getScreenshotSettings(detailGameId);
            ssInterval = s.interval || 3000;
            ssFade = s.fade !== undefined ? s.fade : 800;
        }

        function openWith(id, name, cover, types, rating, status, startDate, finishDate, notes) {
            detailGameId = id; detailGameName = name; detailGameCover = cover;
            try { detailGameTypes = JSON.parse(types) } catch(e) { detailGameTypes = [] }
            // 同步 selectedTags 用于 tagDialog 交互
            selectedTags = detailGameTypes.slice()
            detailGameRating = rating; detailGameStatus = status;
            detailGameStartDate = startDate; detailGameFinishDate = finishDate; detailGameNotes = notes;
            screenshots = dbManager.getScreenshots(id);
            loadScreenshotSettings();
            show();
            requestActivate();
        }

        function refreshScreenshots() {
            screenshots = dbManager.getScreenshots(detailGameId);
            // 重置内嵌轮播状态，避免删除图片后 curIdx 越界
            if (inlineCarousel.curIdx >= screenshots.length) {
                inlineCarousel.curIdx = 0;
                inlineCarousel.front = true;
            }
            // 强制刷新轮播两帧显示（数组内容变化但索引可能未变，绑定不会自动重算）
            if (screenshots.length > 0 && inlineCarousel.curIdx < screenshots.length) {
                var item = screenshots[inlineCarousel.curIdx];
                var sc = item.scale || 1.0;
                var ox = (item.offset_x || 0.0) * inlineImg1.width;
                var oy = (item.offset_y || 0.0) * inlineImg1.height;
                if (inlineCarousel.front) {
                    inlineImg1.source = "file:///" + item.path;
                    inlineScale1.xScale = sc; inlineScale1.yScale = sc;
                    inlineTrans1.x = ox; inlineTrans1.y = oy;
                } else {
                    inlineImg2.source = "file:///" + item.path;
                    inlineScale2.xScale = sc; inlineScale2.yScale = sc;
                    inlineTrans2.x = ox; inlineTrans2.y = oy;
                }
                // 同时刷新另一帧（避免 Timer 切换时显示旧数据）
                var nextIdx = screenshots.length > 1 ? (inlineCarousel.curIdx + 1) % screenshots.length : inlineCarousel.curIdx;
                if (nextIdx < screenshots.length) {
                    var nextItem = screenshots[nextIdx];
                    var nsc = nextItem.scale || 1.0;
                    var nox = (nextItem.offset_x || 0.0) * inlineImg1.width;
                    var noy = (nextItem.offset_y || 0.0) * inlineImg1.height;
                    if (inlineCarousel.front) {
                        inlineImg2.source = "file:///" + nextItem.path;
                        inlineScale2.xScale = nsc; inlineScale2.yScale = nsc;
                        inlineTrans2.x = nox; inlineTrans2.y = noy;
                    } else {
                        inlineImg1.source = "file:///" + nextItem.path;
                        inlineScale1.xScale = nsc; inlineScale1.yScale = nsc;
                        inlineTrans1.x = nox; inlineTrans1.y = noy;
                    }
                }
            }
        }

        Rectangle { anchors.fill: parent; radius: 8; color: root.cBg }
        FramelessDragBar { dialogWindow: gameDetailDialog }
        Rectangle {
            anchors.fill: parent; color: "transparent"

            // 主体左右布局
            Row {
                anchors.fill: parent; anchors.margins: 12; anchors.topMargin: 38; spacing: 12

                // ===== 左侧：封面（宽度随图片比例自适应，最大 40%）=====
                Rectangle {
                    id: coverBox
                    height: parent.height; color: Qt.rgba(root.cCard.r, root.cCard.g, root.cCard.b, 0.7); radius: 10; clip: true
                    property real imgRatio: coverImg.sourceSize.width > 0 ? (coverImg.sourceSize.width / coverImg.sourceSize.height) : 0.7
                    property real maxW: parent.width * 0.40
                    property real wByH: (height - 16) * imgRatio + 16
                    width: wByH > maxW ? maxW : wByH
                    Image {
                        id: coverImg
                        anchors.fill: parent; anchors.margins: 8
                        source: gameDetailDialog.detailGameCover.length > 0 ? "file:///" + gameDetailDialog.detailGameCover : ""
                        fillMode: Image.PreserveAspectFit
                        visible: gameDetailDialog.detailGameCover.length > 0
                    }
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 8; color: Qt.rgba(root.cBorder.r, root.cBorder.g, root.cBorder.b, 0.4); radius: 6; visible: gameDetailDialog.detailGameCover.length === 0
                        Text { anchors.centerIn: parent; text: root.tt("noCover"); color: root.cSub; font.pixelSize: 14 }
                    }
                    // 点击编辑封面提示
                    Rectangle {
                        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 4
                        width: coverEditHint.implicitWidth + 16; height: 22; radius: 11; color: Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.85); visible: coverMouseArea.containsMouse
                        Text { id: coverEditHint; anchors.centerIn: parent; text: "✎ " + root.tt("editCover"); color: "#ffffff"; font.pixelSize: 10 }
                    }
                    MouseArea {
                        id: coverMouseArea; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: gameDetailDialog.changeCover()
                    }
                }

                // ===== 右侧（Flickable 可滚动，底部按钮锚定）=====
                Column {
                    width: parent.width - coverBox.width - 12; height: parent.height; spacing: 8

                    // 可滚动内容区
                    Flickable {
                        id: detailFlickable
                        width: parent.width; height: parent.height - 48; clip: true
                        contentWidth: width; contentHeight: detailCol.height
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: MainSB {}

                        // 点击空白处提交当前编辑（声明在 Column 之前，z 层在下，不阻挡 Column 内控件）
                        MouseArea {
                            anchors.fill: parent
                            propagateComposedEvents: true
                            enabled: gameDetailDialog.editingName || gameDetailDialog.editingRating
                            visible: enabled
                            onPressed: {
                                gameDetailDialog.commitCurrentEdit();
                                mouse.accepted = false;
                            }
                        }

                        Column {
                            id: detailCol; width: parent.width; spacing: 8

                            // 游戏名称（点击编辑，点击空白处确定，宽度自适应）
                            Item {
                                width: gameDetailDialog.editingName
                                       ? Math.min(parent.width, nameEditField.implicitWidth + 8)
                                       : Math.min(parent.width, nameDisplayText.implicitWidth + 4)
                                height: gameDetailDialog.editingName ? 44 : Math.min(60, nameDisplayText.implicitHeight + 4)
                                Text {
                                    id: nameDisplayText
                                    anchors.fill: parent; visible: !gameDetailDialog.editingName
                                    text: gameDetailDialog.detailGameName; font.bold: true; font.pixelSize: 24; color: root.cText
                                    wrapMode: Text.Wrap
                                }
                                MouseArea {
                                    anchors.fill: parent; visible: !gameDetailDialog.editingName
                                    cursorShape: Qt.IBeamCursor
                                    onClicked: gameDetailDialog.startEditName()
                                }
                                TextField {
                                    id: nameEditField
                                    visible: gameDetailDialog.editingName
                                    width: parent.width
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.pixelSize: 16; font.bold: true
                                    text: gameDetailDialog.detailGameName
                                    background: Rectangle { color: root.cInput; radius: 4; border.color: root.cAccent; border.width: 1 }
                                    palette.text: root.cText
                                    onAccepted: gameDetailDialog.saveInlineName(text)
                                    Keys.onEscapePressed: gameDetailDialog.editingName = false
                                }
                            }

                            // 评分（直接点击星星修改）+ 游玩时长 + 状态
                            Flow {
                                width: parent.width; spacing: 10
                                // 可点击星星（Canvas 精确绘制 + 透明点击层叠加）
                                Row {
                                    id: ratingStars; spacing: 2; height: 20
                                    // 星星容器：Canvas 显示 + 透明点击层叠加
                                    Item {
                                        width: 18 * 5 + 2 * 4; height: 18; anchors.verticalCenter: parent.verticalCenter
                                        StarCanvas { rating: gameDetailDialog.detailGameRating; starSize: 18; starGap: 2; anchors.centerIn: parent }
                                        Row {
                                            anchors.fill: parent; spacing: 2
                                            Repeater {
                                                model: 5
                                                Item {
                                                    width: 18; height: 18
                                                    MouseArea { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: parent.width / 2; cursorShape: Qt.PointingHandCursor; onClicked: gameDetailDialog.saveInlineRating(index * 2 + 1) }
                                                    MouseArea { anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: parent.width / 2; cursorShape: Qt.PointingHandCursor; onClicked: gameDetailDialog.saveInlineRating((index + 1) * 2) }
                                                }
                                            }
                                        }
                                    }
                                    // 评分数字：点击进入编辑模式
                                    Text {
                                        visible: !gameDetailDialog.editingRating
                                        text: gameDetailDialog.detailGameRating > 0 ? gameDetailDialog.detailGameRating.toFixed(1) : "✎"
                                        font.pixelSize: 12; color: root.cSub; anchors.verticalCenter: parent.verticalCenter; leftPadding: 4
                                        MouseArea { id: ratingHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: gameDetailDialog.startEditRating() }
                                        ToolTip.text: root.tt("clickToEdit"); ToolTip.visible: ratingHover.containsMouse
                                    }
                                    TextField {
                                        id: ratingEditField
                                        visible: gameDetailDialog.editingRating
                                        width: 56; font.pixelSize: 12; height: 20
                                        placeholderText: "0.0-10.0"; selectByMouse: true
                                        validator: DoubleValidator { bottom: 0.0; top: 10.0; decimals: 1; locale: "C" }
                                        onAccepted: gameDetailDialog.saveInlineRating(text)
                                        onActiveFocusChanged: if (!activeFocus && gameDetailDialog.editingRating) gameDetailDialog.saveInlineRating(text)
                                        background: Rectangle { color: root.cInput; radius: 3; border.color: root.cAccent; border.width: 1 }
                                        palette.text: root.cText; palette.placeholderText: root.cSub
                                        onTextChanged: {
                                            var t = text.replace(/[^0-9.]/g, "");
                                            var parts = t.split(".");
                                            if (parts.length > 2) t = parts[0] + "." + parts.slice(1).join("");
                                            if (t !== text) text = t;
                                            var v = parseFloat(t);
                                            if (!isNaN(v)) {
                                                if (v > 10) text = "10.0";
                                                else if (v < 0) text = "0.0";
                                            }
                                        }
                                        Keys.onEscapePressed: gameDetailDialog.editingRating = false
                                    }
                                }
                                // 游戏状态（点击切换：待玩→进行中→已完成→待玩）
                                Text {
                                    text: "[" + root.statusText(gameDetailDialog.detailGameStatus) + "]"; color: root.cAccent; font.pixelSize: 14; font.bold: true; height: 20; verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight; width: Math.min(implicitWidth + 2, 120)
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: gameDetailDialog.cycleStatus() }
                                }
                                // 游玩日期显示（点击进入日历选择器编辑：开始日期/结束日期分别可改）
                                Item {
                                    height: 20; width: dateRow.implicitWidth
                                    Row {
                                        id: dateRow
                                        spacing: 4; height: parent.height
                                        // 开始日期（点击编辑）
                                        Text {
                                            text: (gameDetailDialog.detailGameStartDate.length > 0)
                                                ? "📅 " + root.formatDate(gameDetailDialog.detailGameStartDate)
                                                : "📅 " + root.tt("selectDate")
                                            color: gameDetailDialog.detailGameStartDate.length > 0 ? root.cAccent : root.cSub
                                            font.pixelSize: 14; height: parent.height; verticalAlignment: Text.AlignVCenter
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: dateSelector.openWith("detailStart", gameDetailDialog.detailGameStartDate) }
                                        }
                                        Text { text: root.tt("toDate"); color: root.cSub; font.pixelSize: 14; height: parent.height; verticalAlignment: Text.AlignVCenter }
                                        // 结束日期（点击编辑）
                                        Text {
                                            text: (gameDetailDialog.detailGameFinishDate.length > 0)
                                                ? root.formatDate(gameDetailDialog.detailGameFinishDate)
                                                : root.tt("selectDate")
                                            color: gameDetailDialog.detailGameFinishDate.length > 0 ? root.cAccent : root.cSub
                                            font.pixelSize: 14; height: parent.height; verticalAlignment: Text.AlignVCenter
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: dateSelector.openWith("detailFinish", gameDetailDialog.detailGameFinishDate) }
                                        }
                                    }
                                }
                            }

                            // 游戏 TAG 显示区域（每行5个，超出自动换行；纯显示，通过右侧"选 TAG"按钮修改）
                            Item {
                                width: parent.width
                                height: gameDetailDialog.detailGameTypes.length === 0 ? 28 : Math.max(28, typeTagGrid.contentHeight + 8)
                                GridView {
                                    id: typeTagGrid
                                    width: parent.width - 90   // 右侧预留 90px 给"选 TAG"按钮
                                    height: contentHeight
                                    anchors.left: parent.left; anchors.top: parent.top; anchors.topMargin: 4
                                    cellWidth: Math.max(60, width / 5)
                                    cellHeight: 26
                                    interactive: false
                                    visible: gameDetailDialog.detailGameTypes.length > 0
                                    model: gameDetailDialog.detailGameTypes
                                    delegate: Rectangle {
                                        width: typeTagGrid.cellWidth - 4
                                        height: 22
                                        radius: 8
                                        color: Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.15); border.color: Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.4); border.width: 1
                                        Text { anchors.centerIn: parent; text: String(modelData).length > 10 ? String(modelData).substring(0, 10) + "…" : modelData; color: root.cAccent; font.pixelSize: 11 }
                                    }
                                }
                                // 空占位提示（无 tag 时显示，引导用户点击右侧"选 TAG"按钮）
                                Text { text: root.tt("noTagHint"); color: root.cSub; font.pixelSize: 10; anchors.left: parent.left; anchors.top: parent.top; anchors.topMargin: 6; width: parent.width - 90; elide: Text.ElideRight; visible: gameDetailDialog.detailGameTypes.length === 0 }
                                // "选 TAG" 按钮（打开 tagDialog 可视化选择，详情页通过 onTagsSaved 回调持久化数据库）
                                Button {
                                    id: detailSelectTagBtn
                                    anchors.right: parent.right; anchors.top: parent.top; anchors.topMargin: 2
                                    text: "+ " + root.tt("selectTag"); flat: true; implicitHeight: 26; implicitWidth: 90
                                    background: Rectangle {
                                        color: detailSelectTagBtn.hovered ? root.cAccent : Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.2)
                                        radius: 4; border.color: root.cAccent; border.width: 1
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    palette.buttonText: detailSelectTagBtn.hovered ? "#ffffff" : root.cAccent; font.pixelSize: 11
                                    onClicked: {
                                        gameDetailDialog.commitCurrentEdit()
                                        // 打开 tagDialog，从 gameDetailDialog.selectedTags 初始化
                                        tagDialog.openWith(gameDetailDialog)
                                    }
                                }
                            }

                            // 分割线
                            Rectangle { width: parent.width; height: 1; color: root.cBorder }

                            // ===== 回忆模块标题行（标题靠左，控制按钮靠右，anchors 布局避免硬编码占位）=====
                            Item {
                                width: parent.width; height: 32
                                Text { text: "📸 " + root.tt("memories"); color: root.cText; font.bold: true; font.pixelSize: 14; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                // 右侧控制组：编辑回忆按钮 → 模式切换按钮 → 模式标签（从右到左排列）
                                BtnGhost { text: root.tt("editMemories"); implicitHeight: 28; implicitWidth: 80; enabled: gameDetailDialog.screenshots.length > 0 || dbManager.getMemoryRoot().length > 0; onClicked: { memoriesEditDialog.openWith(gameDetailDialog.detailGameId) }
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                                Button {
                                    id: gridModeBtn; text: root.tt("gridMode"); flat: true; implicitHeight: 24; implicitWidth: 56
                                    background: Rectangle { color: gridModeBtn.hovered ? root.cAccent : (gameDetailDialog.memDisplayMode === "grid" ? Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.45) : Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.12)); radius: 4; border.color: root.cBorder; border.width: 1; Behavior on color { ColorAnimation { duration: 150 } } }
                                    palette.buttonText: gridModeBtn.hovered ? "#ffffff" : root.cAccent; font.pixelSize: 10
                                    onClicked: gameDetailDialog.memDisplayMode = "grid"
                                    anchors.right: parent.right; anchors.rightMargin: 88; anchors.verticalCenter: parent.verticalCenter
                                }
                                Button {
                                    id: carouselModeBtn; text: root.tt("carouselMode"); flat: true; implicitHeight: 24; implicitWidth: 56
                                    background: Rectangle { color: carouselModeBtn.hovered ? root.cAccent : (gameDetailDialog.memDisplayMode === "carousel" ? Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.45) : Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.12)); radius: 4; border.color: root.cBorder; border.width: 1; Behavior on color { ColorAnimation { duration: 150 } } }
                                    palette.buttonText: carouselModeBtn.hovered ? "#ffffff" : root.cAccent; font.pixelSize: 10
                                    onClicked: gameDetailDialog.memDisplayMode = "carousel"
                                    anchors.right: parent.right; anchors.rightMargin: 88 + 60; anchors.verticalCenter: parent.verticalCenter
                                }
                                Text { text: root.tt("displayMode") + ":"; color: root.cSub; font.pixelSize: 11; anchors.right: parent.right; anchors.rightMargin: 88 + 60 + 60; anchors.verticalCenter: parent.verticalCenter }
                            }

                            // 回忆展示区（16:9 比例，根据模式切换：轮播内嵌 / 网格）
                            Rectangle {
                                id: memDisplayArea
                                width: parent.width; height: Math.round(parent.width * 9 / 16)
                                color: Qt.rgba(root.cCard.r, root.cCard.g, root.cCard.b, 0.5); radius: 8; clip: true; border.color: root.cBorder; border.width: 1
                                Text { anchors.centerIn: parent; visible: gameDetailDialog.screenshots.length === 0; text: root.tt("noScreenshots"); color: root.cSub; font.pixelSize: 14 }

                                // 网格模式（每格 16:9）
                                GridView {
                                    id: ssGrid; anchors.fill: parent; anchors.margins: 6; clip: true
                                    model: gameDetailDialog.screenshots
                                    visible: gameDetailDialog.memDisplayMode === "grid" && gameDetailDialog.screenshots.length > 0
                                    cellWidth: 160; cellHeight: 90
                                    ScrollBar.vertical: MainSB {}
                                    delegate: Rectangle {
                                        width: ssGrid.cellWidth - 6; height: ssGrid.cellHeight - 6; radius: 6; clip: true
                                        color: Qt.rgba(root.cCard.r, root.cCard.g, root.cCard.b, 0.8); border.color: root.cBorder; border.width: 1
                                        Image {
                                            anchors.fill: parent; anchors.margins: 2
                                            source: modelData.path.length > 0 ? "file:///" + modelData.path : ""
                                            fillMode: Image.PreserveAspectFit
                                            transform: [
                                                Scale { origin.x: width/2; origin.y: height/2; xScale: modelData.scale || 1.0; yScale: modelData.scale || 1.0 },
                                                Translate { x: (modelData.offset_x || 0.0) * width; y: (modelData.offset_y || 0.0) * height }
                                            ]
                                        }
                                    }
                                }

                                // 轮播模式（内嵌，非全屏）
                                Item {
                                    id: inlineCarousel; anchors.fill: parent; anchors.margins: 6
                                    visible: gameDetailDialog.memDisplayMode === "carousel" && gameDetailDialog.screenshots.length > 0
                                    clip: true

                                    property int curIdx: 0
                                    property bool front: true

                                    // 双 Image 交叉淡入淡出（与编辑预览样式一致：Scale + Translate）
                                    Image {
                                        id: inlineImg1; anchors.fill: parent
                                        fillMode: Image.PreserveAspectFit
                                        source: gameDetailDialog.screenshots.length > 0 && inlineCarousel.curIdx < gameDetailDialog.screenshots.length ? "file:///" + gameDetailDialog.screenshots[inlineCarousel.curIdx].path : ""
                                        transform: [
                                            Scale { id: inlineScale1; origin.x: inlineImg1.width/2; origin.y: inlineImg1.height/2; xScale: gameDetailDialog.screenshots.length > 0 && inlineCarousel.curIdx < gameDetailDialog.screenshots.length ? (gameDetailDialog.screenshots[inlineCarousel.curIdx].scale || 1.0) : 1.0; yScale: gameDetailDialog.screenshots.length > 0 && inlineCarousel.curIdx < gameDetailDialog.screenshots.length ? (gameDetailDialog.screenshots[inlineCarousel.curIdx].scale || 1.0) : 1.0 },
                                            Translate { id: inlineTrans1; x: gameDetailDialog.screenshots.length > 0 && inlineCarousel.curIdx < gameDetailDialog.screenshots.length ? (gameDetailDialog.screenshots[inlineCarousel.curIdx].offset_x || 0.0) * inlineImg1.width : 0; y: gameDetailDialog.screenshots.length > 0 && inlineCarousel.curIdx < gameDetailDialog.screenshots.length ? (gameDetailDialog.screenshots[inlineCarousel.curIdx].offset_y || 0.0) * inlineImg1.height : 0 }
                                        ]
                                        Behavior on opacity { NumberAnimation { duration: gameDetailDialog.ssFade; easing.type: Easing.InOutQuad } }
                                    }
                                    Image {
                                        id: inlineImg2; anchors.fill: parent
                                        fillMode: Image.PreserveAspectFit; opacity: 0
                                        transform: [
                                            Scale { id: inlineScale2; origin.x: inlineImg2.width/2; origin.y: inlineImg2.height/2; xScale: 1.0; yScale: 1.0 },
                                            Translate { id: inlineTrans2; x: 0; y: 0 }
                                        ]
                                        Behavior on opacity { NumberAnimation { duration: gameDetailDialog.ssFade; easing.type: Easing.InOutQuad } }
                                    }

                                    // 切换定时器
                                    Timer {
                                        id: inlineTimer; interval: gameDetailDialog.ssInterval; repeat: true; running: inlineCarousel.visible && gameDetailDialog.screenshots.length > 1
                                        onTriggered: {
                                            if (gameDetailDialog.screenshots.length < 2) return;
                                            var nextIdx = (inlineCarousel.curIdx + 1) % gameDetailDialog.screenshots.length;
                                            var nextItem = gameDetailDialog.screenshots[nextIdx];
                                            var nextScale = nextItem.scale || 1.0;
                                            var nextOffX = (nextItem.offset_x || 0.0) * inlineImg2.width;
                                            var nextOffY = (nextItem.offset_y || 0.0) * inlineImg2.height;
                                            if (inlineCarousel.front) {
                                                inlineImg2.source = "file:///" + nextItem.path;
                                                inlineScale2.xScale = nextScale; inlineScale2.yScale = nextScale;
                                                inlineTrans2.x = nextOffX; inlineTrans2.y = nextOffY;
                                                inlineImg2.opacity = 1;
                                                inlineImg1.opacity = 0;
                                            } else {
                                                inlineImg1.source = "file:///" + nextItem.path;
                                                inlineScale1.xScale = nextScale; inlineScale1.yScale = nextScale;
                                                inlineTrans1.x = nextOffX; inlineTrans1.y = nextOffY;
                                                inlineImg1.opacity = 1;
                                                inlineImg2.opacity = 0;
                                            }
                                            inlineCarousel.front = !inlineCarousel.front;
                                            inlineCarousel.curIdx = nextIdx;
                                        }
                                    }

                                    // 计数指示
                                    Text { anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 8
                                        text: (inlineCarousel.curIdx + 1) + " / " + gameDetailDialog.screenshots.length
                                        color: "#ffffff"; font.pixelSize: 11
                                        style: Text.Outline; styleColor: "#80000000" }
                                }
                            }

                            // ===== 游戏评价（点击编辑，点击空白处确定）=====
                            Row {
                                width: parent.width; spacing: 6
                                Text { text: "📝 " + root.tt("gameNotes"); color: root.cText; font.bold: true; font.pixelSize: 14; topPadding: 4; anchors.verticalCenter: parent.verticalCenter }
                            }
                            // 显示模式
                            Rectangle {
                                width: parent.width; height: Math.max(60, gameDetailDialog.detailGameNotes.length > 0 ? 100 : 40)
                                color: Qt.rgba(root.cCard.r, root.cCard.g, root.cCard.b, 0.5); radius: 8; border.color: root.cBorder; border.width: 1
                                visible: !gameDetailDialog.editingNotes
                                Text { anchors.fill: parent; anchors.margins: 8; text: gameDetailDialog.detailGameNotes.length > 0 ? gameDetailDialog.detailGameNotes : "—"; color: gameDetailDialog.detailGameNotes.length > 0 ? root.cText : root.cSub; font.pixelSize: 13; wrapMode: Text.Wrap; verticalAlignment: Text.AlignTop }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onClicked: gameDetailDialog.startEditNotes() }
                            }
                            // 编辑模式（带保存/取消按钮）
                            Column {
                                visible: gameDetailDialog.editingNotes
                                width: parent.width; spacing: 6
                                TextArea {
                                    id: notesEditArea
                                    width: parent.width
                                    wrapMode: TextArea.Wrap; font.pixelSize: 13
                                    text: gameDetailDialog.detailGameNotes
                                    background: Rectangle { color: root.cInput; radius: 4; border.color: root.cAccent; border.width: 1 }
                                    palette.text: root.cText
                                    implicitHeight: Math.max(100, contentHeight + 12)
                                    Keys.onEscapePressed: gameDetailDialog.editingNotes = false
                                }
                                Row {
                                    spacing: 8
                                    Button {
                                        id: saveNotesBtn; text: root.tt("saveNotes"); flat: true; implicitHeight: 28; implicitWidth: 70
                                        background: Rectangle { color: saveNotesBtn.hovered ? root.cAccent : Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.85); radius: 4; Behavior on color { ColorAnimation { duration: 150 } } }
                                        palette.buttonText: "#ffffff"; font.pixelSize: 11
                                        onClicked: gameDetailDialog.saveInlineNotes(notesEditArea.text)
                                    }
                                    Button {
                                        id: cancelNotesBtn; text: root.tt("cancelEdit"); flat: true; implicitHeight: 28; implicitWidth: 70
                                        background: Rectangle { color: cancelNotesBtn.hovered ? "#ff4444" : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.1); radius: 4; border.color: cancelNotesBtn.hovered ? "#ff4444" : root.cBorder; border.width: 1; Behavior on color { ColorAnimation { duration: 150 } } }
                                        palette.buttonText: cancelNotesBtn.hovered ? "#ffffff" : root.cSub; font.pixelSize: 11
                                        onClicked: gameDetailDialog.editingNotes = false
                                    }
                                }
                            }
                        }
                    }

                    // ===== 底部：删除按钮（锚定底部）=====
                    Row {
                        width: parent.width; spacing: 8
                        Item { width: parent.width - 90; height: 1 }
                        Button {
                            id: detailDelBtn; text: root.tt("del"); flat: true
                            background: Rectangle { color: detailDelBtn.hovered ? "#ff4444" : "#30ff4444"; radius: 6; border.color: "#ff4444"; border.width: 1; implicitHeight: 32; implicitWidth: 80; Behavior on color { ColorAnimation { duration: 150 } } }
                            palette.buttonText: detailDelBtn.hovered ? "#ffffff" : "#ff4444"
                            onClicked: { deleteDialog.openWith(gameDetailDialog.detailGameId, gameDetailDialog.detailGameName) }
                        }
                    }
                }
            }
        }

        // ===== 回忆编辑对话框（改为 Window，彻底解决居中问题）=====
        Window {
            id: memoriesEditDialog
            transientParent: gameDetailDialog
            flags: Qt.FramelessWindowHint | Qt.Window
            color: "transparent"
            width: 680; height: 500
            title: tt("editMemories")

            // 居中于父窗口（gameDetailDialog），绑定 x/y 实时计算
            x: gameDetailDialog.x + Math.max(24, (gameDetailDialog.width - width) / 2)
            y: gameDetailDialog.y + Math.max(24, (gameDetailDialog.height - height) / 2)

            property int gameId: -1
            property var screenshots: []
            property int currentIdx: -1
            property int ssInterval: 3000
            property int ssFade: 800
            // 当前选中图片的编辑属性
            property real curScale: 1.0
            property real curOffsetX: 0.0
            property real curOffsetY: 0.0
            property int dragFromIndex: -1

            function selectImage(idx) {
                currentIdx = idx;
                if (idx >= 0 && idx < screenshots.length) {
                    var item = screenshots[idx];
                    curScale = item.scale || 1.0;
                    curOffsetX = item.offset_x || 0.0;
                    curOffsetY = item.offset_y || 0.0;
                } else {
                    curScale = 1.0; curOffsetX = 0.0; curOffsetY = 0.0;
                }
            }

            function openWith(gid) {
                gameId = gid;
                screenshots = dbManager.getScreenshots(gid);
                var s = dbManager.getScreenshotSettings(gid);
                ssInterval = s.interval || 3000;
                ssFade = s.fade !== undefined ? s.fade : 800;
                selectImage(screenshots.length > 0 ? 0 : -1);
                show();
            }

            function refresh() {
                screenshots = dbManager.getScreenshots(gameId);
                if (currentIdx >= screenshots.length) currentIdx = screenshots.length - 1;
                if (currentIdx < 0 && screenshots.length > 0) currentIdx = 0;
                selectImage(currentIdx);
                // 排序/删除/添加后：重置轮播播放顺序到第 0 张，确保按新顺序播放
                gameDetailDialog.inlineCarousel.curIdx = 0;
                gameDetailDialog.inlineCarousel.front = true;
                gameDetailDialog.refreshScreenshots();
            }

            function saveSettings() {
                dbManager.setScreenshotSettings(gameId, ssInterval, ssFade);
                gameDetailDialog.ssInterval = ssInterval;
                gameDetailDialog.ssFade = ssFade;
            }

            function resetCurrent() {
                if (currentIdx < 0) return;
                var item = screenshots[currentIdx];
                if (!item) return;
                curScale = 1.0; curOffsetX = 0.0; curOffsetY = 0.0;
                dbManager.setScreenshotScale(item.id, 1.0);
                dbManager.setScreenshotOffset(item.id, 0, 0);
                dbManager.setScreenshotCropMode(item.id, 0);
            }

            onVisibleChanged: {
                if (!visible && gameDetailDialog.visible) {
                    saveSettings();
                    gameDetailDialog.refreshScreenshots();   // 刷新回忆展示，反映编辑后的缩放/位置/排序/增删
                    gameDetailDialog.requestActivate();
                }
            }


            Rectangle { anchors.fill: parent; radius: 8; color: root.cBg }
            FramelessDragBar { dialogWindow: memoriesEditDialog }
            // 主体：左右布局
            Item {
                anchors.top: parent.top; anchors.bottom: memFooter.top; anchors.left: parent.left; anchors.right: parent.right
                anchors.margins: 10; anchors.topMargin: 38

                // ===== 左侧：添加按钮(顶部) + 缩略图列表(拖拽排序) + 删除按钮(底部) =====
                Rectangle {
                    id: memLeftPane
                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                    width: parent.width * 0.36
                    color: Qt.rgba(cCard.r, cCard.g, cCard.b, 0.4); radius: 8; border.color: cBorder; border.width: 1

                    Column {
                        anchors.fill: parent; anchors.margins: 10; spacing: 8

                        // 添加回忆按钮（顶部）
                        Button {
                            id: addMemBtn; text: "+ " + tt("addScreenshot"); flat: true
                            width: parent.width; implicitHeight: 32
                            background: Rectangle { color: addMemBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.2); radius: 6; border.color: cAccent; border.width: 1; Behavior on color { ColorAnimation { duration: 150 } } }
                            palette.buttonText: addMemBtn.hovered ? "#ffffff" : cAccent; font.pixelSize: 12
                            onClicked: screenshotDialogForEdit.open()
                        }

                        // 拖拽排序提示
                        Text { text: tt("dragToReorder"); color: cSub; font.pixelSize: 10; width: parent.width; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter }

                        // 缩略图列表（支持拖拽排序）
                        ListView {
                            id: memList; width: parent.width; height: parent.height - 32 - 18 - 32 - 24; clip: true; spacing: 6
                            model: memoriesEditDialog.screenshots
                            cacheBuffer: 200
                            ScrollBar.vertical: MainSB {}
                            moveDisplaced: Transition { NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutQuad } }

                            delegate: Item {
                                id: memDelegate
                                width: memList.width; height: 64

                                Rectangle {
                                    id: memDelegateBg
                                    x: 0; y: 0; width: parent.width; height: parent.height
                                    radius: 6; clip: true
                                    color: memoriesEditDialog.currentIdx === index ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.22) : Qt.rgba(cCard.r, cCard.g, cCard.b, 0.6)
                                    border.color: memoriesEditDialog.currentIdx === index ? cAccent : cBorder
                                    border.width: memoriesEditDialog.currentIdx === index ? 2 : 1

                                    // 选中点击区域（声明在 Row 之前，z 层在下方，不阻挡拖拽手柄的 press）
                                    // 已移除：改为缩略图和序号区各自独立 MouseArea，避免覆盖拖拽手柄

                                    Row {
                                        anchors.fill: parent; anchors.margins: 6; spacing: 6

                                        // 拖拽手柄（⠿ 图标区域，唯一可触发拖拽排序的区域）
                                        Rectangle {
                                            width: 18; height: parent.height; color: "transparent"; z: 10
                                            Text { anchors.centerIn: parent; text: "⠿"; color: cSub; font.pixelSize: 14 }
                                            MouseArea {
                                                id: dragHandleMA
                                                anchors.fill: parent
                                                cursorShape: Qt.SizeAllCursor
                                                hoverEnabled: true
                                                preventStealing: true
                                                z: 10
                                                property real startY: 0
                                                onPressed: {
                                                    startY = mouseY;
                                                    memoriesEditDialog.dragFromIndex = index;
                                                    memList.interactive = false;
                                                    dragCloneItem.visible = true;
                                                    dragCloneItem.fromIndex = index;
                                                    dragCloneItem.itemData = modelData;
                                                    var pos = memDelegate.mapToItem(memoriesEditDialog.contentItem, 0, 0);
                                                    dragCloneItem.x = pos.x;
                                                    dragCloneItem.y = pos.y;
                                                    dragCloneItem.startY = pos.y;
                                                    dragCloneItem.dragOffset = 0;
                                                    memDelegateBg.opacity = 0.3;
                                                }
                                                onPositionChanged: {
                                                    var dy = mouseY - startY;
                                                    dragCloneItem.y = dragCloneItem.startY + dy;
                                                    dragCloneItem.dragOffset = dy;
                                                }
                                                onReleased: {
                                                    memList.interactive = true;
                                                    dragCloneItem.visible = false;
                                                    memDelegateBg.opacity = 1.0;
                                                    if (Math.abs(dragCloneItem.dragOffset) < 5) {
                                                        memoriesEditDialog.selectImage(index);
                                                    } else {
                                                        var step = memDelegate.height + memList.spacing;
                                                        var targetIdx = index + Math.round(dragCloneItem.dragOffset / step);
                                                        targetIdx = Math.max(0, Math.min(memList.count - 1, targetIdx));
                                                        if (targetIdx !== index) {
                                                            var arr = memoriesEditDialog.screenshots.slice();
                                                            var item = arr[index];
                                                            if (item) {
                                                                arr.splice(index, 1);
                                                                arr.splice(targetIdx, 0, item);
                                                                memoriesEditDialog.screenshots = arr;
                                                                dbManager.reorderScreenshot(item.id, targetIdx);
                                                                memoriesEditDialog.refresh();
                                                                // 选中拖动后新位置的图片，便于继续编辑
                                                                memoriesEditDialog.selectImage(targetIdx);
                                                            }
                                                        }
                                                    }
                                                    memoriesEditDialog.dragFromIndex = -1;
                                                }
                                                onCanceled: {
                                                    memList.interactive = true;
                                                    dragCloneItem.visible = false;
                                                    memDelegateBg.opacity = 1.0;
                                                    memoriesEditDialog.dragFromIndex = -1;
                                                }
                                            }
                                        }

                                        // 缩略图（点击选中）
                                        Rectangle {
                                            width: 48; height: 48; radius: 4; clip: true; color: cBorder
                                            Image {
                                                anchors.fill: parent; anchors.margins: 1
                                                source: modelData.path.length > 0 ? "file:///" + modelData.path : ""
                                                fillMode: Image.PreserveAspectCrop
                                            }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: memoriesEditDialog.selectImage(index) }
                                        }

                                        // 序号显示（剩余空间，点击可选中图片）
                                        Item {
                                            width: parent.width - 18 - 48 - 6*3; height: parent.height
                                            Text {
                                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                                text: "#" + (index + 1)
                                                color: cSub; font.pixelSize: 11
                                            }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: memoriesEditDialog.selectImage(index) }
                                        }
                                    }
                                }
                            }

                            Text { anchors.centerIn: parent; visible: memoriesEditDialog.screenshots.length === 0; text: tt("noScreenshots"); color: cSub; font.pixelSize: 13 }
                        }

                        // 删除当前选中回忆按钮（底部）
                        Button {
                            id: delMemBtn; text: "🗑 " + tt("deleteMemory"); flat: true
                            width: parent.width; implicitHeight: 32
                            enabled: memoriesEditDialog.currentIdx >= 0
                            background: Rectangle { color: enabled ? (delMemBtn.hovered ? "#ff4444" : "#30ff4444") : Qt.rgba(cText.r, cText.g, cText.b, 0.05); radius: 6; border.color: enabled ? "#ff4444" : cBorder; border.width: 1; Behavior on color { ColorAnimation { duration: 150 } } }
                            palette.buttonText: enabled ? (delMemBtn.hovered ? "#ffffff" : "#ff4444") : cSub; font.pixelSize: 12
                            onClicked: {
                                if (memoriesEditDialog.currentIdx < 0) return;
                                var item = memoriesEditDialog.screenshots[memoriesEditDialog.currentIdx];
                                if (item) { dbManager.deleteScreenshot(item.id); memoriesEditDialog.refresh() }
                            }
                        }
                    }
                }

                // ===== 右侧：图片编辑器（仅适配模式）=====
                Rectangle {
                    id: memRightPane
                    anchors.left: memLeftPane.right; anchors.leftMargin: 10; anchors.top: parent.top; anchors.right: parent.right; anchors.bottom: parent.bottom
                    color: Qt.rgba(cCard.r, cCard.g, cCard.b, 0.4); radius: 8; border.color: cBorder; border.width: 1

                    // 右面板内容（方案C：Flickable + ColumnLayout，与主页面缩放设置一致）
                    Flickable {
                        id: memRightFlick
                        anchors.fill: parent; anchors.margins: 10
                        clip: true; contentWidth: width; contentHeight: memRightCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: MainSB {}

                        ColumnLayout {
                            id: memRightCol
                            width: parent.width; spacing: 8

                            // 预览区域（16:9 比例，等比例真实展示图片）
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: Math.round(width * 9 / 16); radius: 6; clip: true
                                color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.08); border.color: cBorder; border.width: 1
                                Text { anchors.centerIn: parent; visible: memoriesEditDialog.currentIdx < 0; text: tt("noScreenshots"); color: cSub; font.pixelSize: 13 }

                                Item {
                                    id: memPreviewContainer
                                    anchors.fill: parent; anchors.margins: 8
                                    visible: memoriesEditDialog.currentIdx >= 0

                                    Image {
                                        id: memPreviewImg
                                        anchors.fill: parent
                                        source: {
                                            var item = memoriesEditDialog.currentIdx >= 0 ? memoriesEditDialog.screenshots[memoriesEditDialog.currentIdx] : null;
                                            return (item && item.path.length > 0) ? "file:///" + item.path : "";
                                        }
                                        fillMode: Image.PreserveAspectFit
                                        clip: true
                                        transform: [
                                            Scale { origin.x: memPreviewImg.width/2; origin.y: memPreviewImg.height/2; xScale: memoriesEditDialog.curScale; yScale: memoriesEditDialog.curScale },
                                            Translate { x: memoriesEditDialog.curOffsetX * memPreviewImg.width; y: memoriesEditDialog.curOffsetY * memPreviewImg.height }
                                        ]
                                    }

                                    // 中心十字辅助线
                                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 1; height: parent.height; color: Qt.rgba(255, 255, 255, 0.1) }
                                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.1) }

                                    MouseArea {
                                        anchors.fill: parent
                                        property point dragStart
                                        property real startOffX
                                        property real startOffY
                                        onPressed: function(mouse) {
                                            if (memoriesEditDialog.currentIdx < 0) return;
                                            dragStart = Qt.point(mouseX, mouseY);
                                            startOffX = memoriesEditDialog.curOffsetX;
                                            startOffY = memoriesEditDialog.curOffsetY;
                                        }
                                        onPositionChanged: function(mouse) {
                                            if (memoriesEditDialog.currentIdx < 0) return;
                                            var dx = (mouseX - dragStart.x) / memPreviewContainer.width;
                                            var dy = (mouseY - dragStart.y) / memPreviewContainer.height;
                                            var nx = startOffX + dx;
                                            var ny = startOffY + dy;
                                            var item = memoriesEditDialog.screenshots[memoriesEditDialog.currentIdx];
                                            if (item) dbManager.setScreenshotOffset(item.id, nx, ny);
                                            memoriesEditDialog.curOffsetX = nx;
                                            memoriesEditDialog.curOffsetY = ny;
                                        }
                                        onWheel: function(wheel) {
                                            if (memoriesEditDialog.currentIdx < 0) return;
                                            var delta = wheel.angleDelta.y > 0 ? 0.1 : -0.1;
                                            var ns = Math.max(0.1, Math.min(10.0, memoriesEditDialog.curScale + delta));
                                            memoriesEditDialog.curScale = ns;
                                            var item = memoriesEditDialog.screenshots[memoriesEditDialog.currentIdx];
                                            if (item) dbManager.setScreenshotScale(item.id, ns);
                                        }
                                        cursorShape: Qt.SizeAllCursor
                                    }
                                }
                            }

                            // 状态信息（预览区下方，不挡图片）
                            RowLayout {
                                Layout.fillWidth: true; spacing: 8
                                Text { text: tt("dragToAdjustPos") + " · 滚轮缩放"; color: cSub; font.pixelSize: 10; visible: memoriesEditDialog.currentIdx >= 0; Layout.fillWidth: true; elide: Text.ElideRight }
                                Text { text: tt("imageScale") + " " + memoriesEditDialog.curScale.toFixed(2) + "  " + tt("imagePosition") + " " + memoriesEditDialog.curOffsetX.toFixed(2) + "," + memoriesEditDialog.curOffsetY.toFixed(2); color: cSub; font.pixelSize: 10; visible: memoriesEditDialog.currentIdx >= 0; Layout.fillWidth: true; elide: Text.ElideRight; horizontalAlignment: Text.AlignRight }
                            }

                            // 缩放滑块行
                            RowLayout {
                                Layout.fillWidth: true; spacing: 8
                                Text { text: tt("imageScale"); color: cText; font.pixelSize: 11; Layout.preferredWidth: 36; elide: Text.ElideRight }
                                RoundSlider {
                                    from: 0.1; to: 10.0; stepSize: 0.05; value: memoriesEditDialog.curScale; enabled: memoriesEditDialog.currentIdx >= 0
                                    onMoved: {
                                        memoriesEditDialog.curScale = value;
                                        var item = memoriesEditDialog.screenshots[memoriesEditDialog.currentIdx];
                                        if (item) dbManager.setScreenshotScale(item.id, value);
                                    }
                                    Layout.fillWidth: true
                                }
                                Text { text: memoriesEditDialog.curScale.toFixed(1); color: cSub; font.pixelSize: 11; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignHCenter }
                            }

                            // 三个重置按钮同一行靠右
                            Row {
                                Layout.fillWidth: true; spacing: 8; layoutDirection: Qt.RightToLeft
                                Button {
                                    id: resetAllBtn; text: tt("resetAll"); flat: true; implicitHeight: 26; implicitWidth: 80; enabled: memoriesEditDialog.currentIdx >= 0
                                    background: Rectangle { color: enabled ? (resetAllBtn.hovered ? "#ff4444" : "#30ff4444") : Qt.rgba(cText.r, cText.g, cText.b, 0.05); radius: 4; border.color: enabled ? "#ff4444" : cBorder; border.width: 1; Behavior on color { ColorAnimation { duration: 150 } } }
                                    palette.buttonText: enabled ? (resetAllBtn.hovered ? "#ffffff" : "#ff4444") : cSub; font.pixelSize: 10
                                    onClicked: memoriesEditDialog.resetCurrent()
                                }
                                Button {
                                    id: resetPosBtn; text: tt("resetPosition"); flat: true; implicitHeight: 26; implicitWidth: 90; enabled: memoriesEditDialog.currentIdx >= 0
                                    background: Rectangle { color: enabled ? (resetPosBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12)) : Qt.rgba(cText.r, cText.g, cText.b, 0.05); radius: 4; border.color: enabled ? (resetPosBtn.hovered ? cAccent : cBorder) : cBorder; border.width: 1; Behavior on color { ColorAnimation { duration: 150 } } }
                                    palette.buttonText: enabled ? (resetPosBtn.hovered ? "#ffffff" : cAccent) : cSub; font.pixelSize: 10
                                    onClicked: {
                                        memoriesEditDialog.curOffsetX = 0; memoriesEditDialog.curOffsetY = 0;
                                        var item = memoriesEditDialog.screenshots[memoriesEditDialog.currentIdx];
                                        if (item) dbManager.setScreenshotOffset(item.id, 0, 0);
                                    }
                                }
                                Button {
                                    id: resetScaleBtn; text: tt("resetScale"); flat: true; implicitHeight: 26; implicitWidth: 72; enabled: memoriesEditDialog.currentIdx >= 0
                                    background: Rectangle { color: enabled ? (resetScaleBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12)) : Qt.rgba(cText.r, cText.g, cText.b, 0.05); radius: 4; border.color: enabled ? (resetScaleBtn.hovered ? cAccent : cBorder) : cBorder; border.width: 1; Behavior on color { ColorAnimation { duration: 150 } } }
                                    palette.buttonText: enabled ? (resetScaleBtn.hovered ? "#ffffff" : cAccent) : cSub; font.pixelSize: 10
                                    onClicked: {
                                        memoriesEditDialog.curScale = 1.0;
                                        var item = memoriesEditDialog.screenshots[memoriesEditDialog.currentIdx];
                                        if (item) dbManager.setScreenshotScale(item.id, 1.0);
                                    }
                                }
                            }

                            // 分割线
                            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(cBorder.r, cBorder.g, cBorder.b, 0.5) }

                            // 轮播参数
                            RowLayout {
                                Layout.fillWidth: true; spacing: 8
                                Text { text: tt("playInterval"); color: cText; font.pixelSize: 11; Layout.preferredWidth: 60; elide: Text.ElideRight }
                                RoundSlider { from: 500; to: 10000; stepSize: 100; value: memoriesEditDialog.ssInterval; onMoved: memoriesEditDialog.ssInterval = value; Layout.fillWidth: true }
                                Text { text: (memoriesEditDialog.ssInterval / 1000).toFixed(1) + tt("seconds"); color: cSub; font.pixelSize: 11; Layout.preferredWidth: 52; horizontalAlignment: Text.AlignHCenter }
                            }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 8
                                Text { text: tt("fadeDuration"); color: cText; font.pixelSize: 11; Layout.preferredWidth: 60; elide: Text.ElideRight }
                                RoundSlider { from: 0; to: 3000; stepSize: 50; value: memoriesEditDialog.ssFade; onMoved: memoriesEditDialog.ssFade = value; Layout.fillWidth: true }
                                Text { text: (memoriesEditDialog.ssFade / 1000).toFixed(1) + tt("seconds"); color: cSub; font.pixelSize: 11; Layout.preferredWidth: 52; horizontalAlignment: Text.AlignHCenter }
                            }
                        }
                    }
                }
            }

            // 底部按钮栏
            Rectangle {
                id: memFooter
                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                height: 44; color: "transparent"
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: cBorder }
                Row {
                    anchors.centerIn: parent; spacing: 10
                    Button {
                        id: saveMemBtn; text: tt("save"); flat: true; implicitHeight: 30; implicitWidth: 80
                        background: Rectangle { color: saveMemBtn.hovered ? Qt.darker(cAccent, 1.2) : cAccent; radius: 4; Behavior on color { ColorAnimation { duration: 150 } } }
                        palette.buttonText: "#ffffff"; font.pixelSize: 12
                        onClicked: { memoriesEditDialog.saveSettings(); memoriesEditDialog.hide() }
                    }
                    Button {
                        id: closeMemBtn; text: tt("close"); flat: true; implicitHeight: 30; implicitWidth: 80
                        background: Rectangle { color: closeMemBtn.hovered ? "#ff4444" : Qt.rgba(cText.r, cText.g, cText.b, 0.1); radius: 4; border.color: closeMemBtn.hovered ? "#ff4444" : cBorder; border.width: 1; Behavior on color { ColorAnimation { duration: 150 } } }
                        palette.buttonText: closeMemBtn.hovered ? "#ffffff" : cSub; font.pixelSize: 12
                        onClicked: { memoriesEditDialog.saveSettings(); memoriesEditDialog.hide() }
                    }
                }
            }

            // 拖拽浮动克隆（Window 直接子元素，z:1000 最上层，不被 ListView clip 裁切）
            Item {
                id: dragCloneItem
                visible: false; z: 1000
                width: memList.width; height: 64
                property int fromIndex: -1
                property var itemData: null
                property real startY: 0
                property real dragOffset: 0
                Rectangle {
                    anchors.fill: parent; radius: 6; color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4); border.color: cAccent; border.width: 2; opacity: 0.85
                    Row {
                        anchors.fill: parent; anchors.margins: 6; spacing: 6
                        Rectangle { width: 18; height: parent.height; color: "transparent"; Text { anchors.centerIn: parent; text: "⠿"; color: cSub; font.pixelSize: 14 } }
                        Rectangle {
                            width: 48; height: 48; radius: 4; clip: true; color: cBorder
                            Image { anchors.fill: parent; anchors.margins: 1; source: dragCloneItem.itemData && dragCloneItem.itemData.path.length > 0 ? "file:///" + dragCloneItem.itemData.path : ""; fillMode: Image.PreserveAspectCrop }
                        }
                        Text { width: parent.width - 18 - 48 - 6*3; height: parent.height; verticalAlignment: Text.AlignVCenter; text: dragCloneItem.fromIndex >= 0 ? "#" + (dragCloneItem.fromIndex + 1) : ""; color: cSub; font.pixelSize: 11 }
                    }
                }
            }
        }
    }

    FileDialog {
        id: screenshotDialogForEdit; title: tt("addScreenshot")
        nameFilters: ["图片文件 (*.jpg *.jpeg *.png *.bmp *.webp)"]
        onAccepted: {
            var result = dbManager.importScreenshot(memoriesEditDialog.gameId, urlToPath(currentFile));
            if (result.length > 0) { memoriesEditDialog.refresh(); }
            else { root.warn(tt("importScreenshotFail")); }
        }
    }

    // 详情窗内联封面更换（选文件→裁剪→保存）
    FileDialog {
        id: coverPickerForDetail; title: tt("editCover")
        nameFilters: ["图片文件 (*.jpg *.jpeg *.png *.bmp *.webp)"]
        onAccepted: { cropDialog.openCoverForDetail(urlToPath(currentFile)) }
    }

    // ===== 游戏 TAG 选择对话框（独立 Window，上块系统默认+搜索栏，下块用户自定义+加号添加+删除）=====
    // 多父对话框支持：openWith(dialog) 传入调用方对话框（addDialog/editDialog/gameDetailDialog）
    // 保存时写回 dialog.selectedTags，并调用 dialog.onTagsSaved 回调（若有，详情页用于持久化数据库）
    Window {
        id: tagDialog
        flags: Qt.FramelessWindowHint | Qt.Window
        color: "transparent"
        title: tt("tagTitle")
        width: 600; height: 560
        minimumWidth: 560; minimumHeight: 520
        // x/y 动态跟随父对话框居中（在 openWith 中根据 targetDialog 计算）
        palette.window: cCard; palette.windowText: cText; palette.text: cText; palette.button: cCard; palette.buttonText: cText; palette.base: cInput; palette.placeholderText: cSub; palette.highlight: cAccent; palette.highlightedText: "#ffffff"

        property var targetDialog: null     // 调用方对话框（addDialog/editDialog/gameDetailDialog），用于读写 selectedTags 和 transientParent
        property var selectedTags: []       // 当前已选 TAG 列表（本地副本，保存时写回 targetDialog.selectedTags）
        property string searchKey: ""       // 系统默认类型搜索关键词

        function openWith(dialog) {
            targetDialog = dialog
            // 设置 transientParent 实现层级关系（tagDialog 跟随父对话框）
            if (dialog) {
                transientParent = dialog
                // 居中于父对话框
                x = dialog.x + Math.max(24, (dialog.width - width) / 2)
                y = dialog.y + Math.max(24, (dialog.height - height) / 2)
                // 从 dialog.selectedTags 初始化本地副本（统一接口：所有调用方都有 selectedTags 属性）
                var src = dialog.selectedTags || []
                selectedTags = src.slice()
            } else {
                transientParent = root
                x = root.x + (root.width - width) / 2
                y = root.y + (root.height - height) / 2
                selectedTags = []
            }
            searchKey = ""
            tagInputField.text = ""
            show()
        }
        function toggleTag(tag) {
            var idx = selectedTags.indexOf(tag)
            var l = selectedTags.slice()
            if (idx < 0) l.push(tag)
            else l.splice(idx, 1)
            selectedTags = l
        }
        function addCustomTag() {
            var t = tagInputField.text.trim()
            if (t.length === 0) return
            // 检查与系统默认或已有自定义重复（用户要求"与系统内置一样则无法添加并提示"）
            if (root.systemTags.indexOf(t) >= 0 || root.customTags.indexOf(t) >= 0) {
                warn(tt("tagExists"))
                return
            }
            var l = root.customTags.slice()
            l.push(t)
            root.customTags = l
            dbManager.setSetting("customTags", JSON.stringify(l))   // 持久化
            tagInputField.text = ""
            toggleTag(t)   // 自动选中新添加的 tag
        }
        function removeCustomTag(tag) {
            var l = root.customTags.slice()
            var idx = l.indexOf(tag)
            if (idx >= 0) l.splice(idx, 1)
            root.customTags = l
            dbManager.setSetting("customTags", JSON.stringify(l))   // 持久化
            var sidx = selectedTags.indexOf(tag)
            if (sidx >= 0) {
                var sl = selectedTags.slice()
                sl.splice(sidx, 1)
                selectedTags = sl
            }
        }
        function saveTags() {
            // 写回 targetDialog.selectedTags（触发对话框内 Flow+Repeater 刷新）
            if (targetDialog) {
                targetDialog.selectedTags = selectedTags.slice()
            }
            // 若调用方有 onTagsSaved 回调（如详情页需要同步 detailGameTypes + 持久化数据库），则调用
            if (targetDialog && targetDialog.onTagsSaved) {
                targetDialog.onTagsSaved(selectedTags.slice())
            }
            hide()
        }

        Rectangle { anchors.fill: parent; radius: 8; color: root.cBg }
        FramelessDragBar { dialogWindow: tagDialog }
        // 内容区（Flickable 包裹，内容超出时可滚动，不会遮挡底部按钮）
        Flickable {
            anchors.fill: parent; anchors.margins: 12
            anchors.topMargin: 38; anchors.bottomMargin: 50   // 底部预留 50px 给固定按钮栏
            clip: true; contentWidth: width; contentHeight: tagContentCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: MainSB {}
            Column {
                id: tagContentCol
                width: parent.width; spacing: 8

                // 标题
                Text { text: tt("tagTitle"); color: cText; font.bold: true; font.pixelSize: 14 }

                // ===== 统一搜索/添加输入框（搜索过滤+未匹配时可添加为新 TAG）=====
                TextField {
                    id: tagInputField
                    width: parent.width; font.pixelSize: 12
                    placeholderText: tt("tagSearch")
                    background: InputBg {}
                    onTextChanged: tagDialog.searchKey = text.trim().toLowerCase()
                    onAccepted: {
                        // 回车：若输入内容未匹配现有 tag，则添加为新自定义 tag
                        var txt = text.trim()
                        if (txt.length === 0) return
                        var all = root.systemTags.concat(root.customTags)
                        var matched = false
                        for (var i = 0; i < all.length; i++) {
                            if (all[i].toLowerCase() === txt.toLowerCase()) { matched = true; break }
                        }
                        if (!matched) tagDialog.addCustomTag()
                    }
                }
                // "+ 添加新 TAG：xxx" 按钮（输入内容未匹配现有 tag 时显示）
                Button {
                    id: addNewTagBtn
                    visible: {
                        var txt = tagInputField.text.trim()
                        if (txt.length === 0) return false
                        var all = root.systemTags.concat(root.customTags)
                        for (var i = 0; i < all.length; i++) {
                            if (all[i].toLowerCase() === txt.toLowerCase()) return false
                        }
                        return true
                    }
                    text: "+ " + tt("tagAdd") + "：" + tagInputField.text.trim()
                    flat: true; implicitHeight: 28; width: parent.width
                    background: Rectangle {
                        color: addNewTagBtn.hovered ? cAccent : Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15)
                        radius: 4; border.color: cAccent; border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    palette.buttonText: addNewTagBtn.hovered ? "#ffffff" : cAccent; font.pixelSize: 11
                    onClicked: tagDialog.addCustomTag()
                }

                // ===== 系统默认 TAG =====
                Text { text: tt("tagSystem"); color: cSub; font.pixelSize: 12 }
                // 系统默认 tag 列表（Flickable + Flow 自动换行，一行5个按钮式，hover 效果）
                Flickable {
                    width: parent.width; height: 160; clip: true
                    contentWidth: width; contentHeight: systemTagFlow.height
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: MainSB {}
                    Flow {
                        id: systemTagFlow
                        width: parent.width; spacing: 6
                        Repeater {
                            model: {
                                var key = tagDialog.searchKey
                                if (key.length === 0) return root.systemTags
                                return root.systemTags.filter(function(t){return t.toLowerCase().indexOf(key) >= 0})
                            }
                            delegate: Rectangle {
                                width: (systemTagFlow.width - 6*4) / 5; height: 30; radius: 6
                                property bool isSelected: tagDialog.selectedTags.indexOf(modelData) >= 0
                                property bool isHovered: sysTagMA.containsMouse
                                color: isSelected ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.75) : (isHovered ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.18) : Qt.rgba(cCard.r, cCard.g, cCard.b, 0.7))
                                border.color: isSelected ? cAccent : (isHovered ? cAccent : cBorder); border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                Text { anchors.centerIn: parent; text: modelData; color: isSelected ? "#ffffff" : cText; font.pixelSize: 11 }
                                MouseArea {
                                    id: sysTagMA
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: tagDialog.toggleTag(modelData)
                                }
                            }
                        }
                    }
                }

                // 分割线
                Rectangle { width: parent.width; height: 1; color: Qt.rgba(cBorder.r, cBorder.g, cBorder.b, 0.5) }

                // ===== 用户自定义 TAG =====
                Text { text: tt("tagCustom"); color: cSub; font.pixelSize: 12 }
                // 用户自定义 tag 列表（每个右上角 ✕ 删除）
                Flickable {
                    width: parent.width; height: 100; clip: true
                    contentWidth: width; contentHeight: customTagFlow.height
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: MainSB {}
                    Flow {
                        id: customTagFlow
                        width: parent.width; spacing: 6
                        Repeater {
                            model: {
                                // 自定义 tag 列表也受搜索关键词过滤
                                var key = tagDialog.searchKey
                                if (key.length === 0) return root.customTags
                                return root.customTags.filter(function(t){return t.toLowerCase().indexOf(key) >= 0})
                            }
                            delegate: Rectangle {
                                width: (customTagFlow.width - 6*4) / 5; height: 30; radius: 6
                                property bool isSelected: tagDialog.selectedTags.indexOf(modelData) >= 0
                                property bool isHovered: cusTagMA.containsMouse
                                color: isSelected ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.75) : (isHovered ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.18) : Qt.rgba(cCard.r, cCard.g, cCard.b, 0.7))
                                border.color: isSelected ? cAccent : (isHovered ? cAccent : cBorder); border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                Text { anchors.left: parent.left; anchors.leftMargin: 6; anchors.verticalCenter: parent.verticalCenter; text: modelData; color: isSelected ? "#ffffff" : cText; font.pixelSize: 11 }
                                // 点击切换选中（z:0 底层）
                                MouseArea {
                                    id: cusTagMA
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; z: 0
                                    onClicked: tagDialog.toggleTag(modelData)
                                }
                                // 删除按钮（右上角 ✕，z:1 高层优先接收点击）
                                Rectangle {
                                    anchors.right: parent.right; anchors.rightMargin: 3; anchors.top: parent.top; anchors.topMargin: 3
                                    width: 14; height: 14; radius: 7; z: 1
                                    color: cusDelMA.containsMouse ? "#ff4444" : "transparent"
                                    border.color: cusDelMA.containsMouse ? "#ff4444" : (isSelected ? "#ffffff" : cSub); border.width: 1
                                    Text { anchors.centerIn: parent; text: "✕"; color: cusDelMA.containsMouse ? "#ffffff" : (isSelected ? "#ffffff" : cSub); font.pixelSize: 8 }
                                    MouseArea {
                                        id: cusDelMA
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; z: 1
                                        onClicked: tagDialog.removeCustomTag(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
                // 占位提示（无自定义 tag 时）
                Text { visible: root.customTags.length === 0; text: "—"; color: cSub; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
        // ===== 底部固定按钮栏（anchors 固定在窗口底部，始终可见不被内容遮挡）=====
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: 44; color: "transparent"
            Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: Qt.rgba(cBorder.r, cBorder.g, cBorder.b, 0.5) }
            Row {
                anchors.fill: parent; anchors.margins: 8; spacing: 8
                Text {
                    text: tt("tagSelected") + "：" + tagDialog.selectedTags.length
                    color: cSub; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                    Layout.fillWidth: true
                }
                Row {
                    spacing: 8; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    Button {
                        text: tt("save"); flat: true; implicitHeight: 30; implicitWidth: 80
                        background: Rectangle { color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.2); radius: 4; border.color: cAccent; border.width: 1 }
                        palette.buttonText: cAccent; font.pixelSize: 12
                        onClicked: tagDialog.saveTags()
                    }
                    Button {
                        id: tagCancelBtn
                        text: tt("cancelEdit"); flat: true; implicitHeight: 30; implicitWidth: 80
                        background: Rectangle {
                            color: tagCancelBtn.hovered ? "#ff4444" : Qt.rgba(cText.r, cText.g, cText.b, 0.1)
                            radius: 4; border.color: tagCancelBtn.hovered ? "#ff4444" : cBorder; border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                        palette.buttonText: tagCancelBtn.hovered ? "#ffffff" : cSub; font.pixelSize: 12
                        onClicked: tagDialog.hide()
                    }
                }
            }
        }
    }

    // ===== 日期选择器 Popup（轻量日历，供 addDialog/editDialog 选择游玩日期）=====
    Popup {
        id: dateSelector
        property string targetField: ""   // "addStart"/"addFinish"/"editStart"/"editFinish"
        property var selectedDate: new Date()
        property int viewYear: new Date().getFullYear()
        property int viewMonth: new Date().getMonth()
        width: 280; height: 380
        modal: true
        background: Rectangle { color: root.cCard; radius: 8; border.color: root.cBorder; border.width: 1 }

        function openWith(field, dateStr) {
            targetField = field
            if (dateStr && dateStr.length > 0) {
                var d = root.ymdToDate(dateStr)
                selectedDate = d
                viewYear = d.getFullYear()
                viewMonth = d.getMonth()
            } else {
                selectedDate = new Date()
                viewYear = new Date().getFullYear()
                viewMonth = new Date().getMonth()
            }
            // 根据目标字段设置父窗口，确保 Popup 显示在对应对话框之上，并计算居中坐标
            var pw = 0, ph = 0
            if (field === "addStart" || field === "addFinish") {
                parent = addDialog.contentItem
                pw = addDialog.width; ph = addDialog.height
            } else if (field === "editStart" || field === "editFinish") {
                parent = editDialog.contentItem
                pw = editDialog.width; ph = editDialog.height
            } else if (field === "detailStart" || field === "detailFinish") {
                parent = gameDetailDialog.contentItem
                pw = gameDetailDialog.width; ph = gameDetailDialog.height
            }
            // 居中于父对话框（width/height 为 Popup 自身尺寸 280×380）
            x = Math.max(0, (pw - width) / 2)
            y = Math.max(0, (ph - height) / 2)
            open()
        }

        function writeBack(ymd) {
            var displayText = ymd.length > 0 ? root.formatDate(ymd) : root.tt("selectDate")
            if (targetField === "addStart") { addDialog.startDateValue = ymd; addStartDateBtn.text = displayText }
            else if (targetField === "addFinish") { addDialog.finishDateValue = ymd; addFinishDateBtn.text = displayText }
            else if (targetField === "editStart") { editDialog.startDateValue = ymd; editStartDateBtn.text = displayText }
            else if (targetField === "editFinish") { editDialog.finishDateValue = ymd; editFinishDateBtn.text = displayText }
            else if (targetField === "detailStart") {
                // 详情页日期修改：同步属性 + 持久化数据库 + 刷新列表
                gameDetailDialog.detailGameStartDate = ymd
                dbManager.updateGame(gameDetailDialog.detailGameId, gameDetailDialog.detailGameName, gameDetailDialog.detailGameTypes,
                    gameDetailDialog.detailGameRating, gameDetailDialog.detailGameStatus, 0,
                    gameDetailDialog.detailGameStartDate, gameDetailDialog.detailGameFinishDate,
                    gameDetailDialog.detailGameNotes, gameDetailDialog.detailGameCover)
                gameListModel.refresh(searchField.text)
            } else if (targetField === "detailFinish") {
                gameDetailDialog.detailGameFinishDate = ymd
                dbManager.updateGame(gameDetailDialog.detailGameId, gameDetailDialog.detailGameName, gameDetailDialog.detailGameTypes,
                    gameDetailDialog.detailGameRating, gameDetailDialog.detailGameStatus, 0,
                    gameDetailDialog.detailGameStartDate, gameDetailDialog.detailGameFinishDate,
                    gameDetailDialog.detailGameNotes, gameDetailDialog.detailGameCover)
                gameListModel.refresh(searchField.text)
            }
        }

        Column {
            anchors.fill: parent; spacing: 8; clip: true

            // 月份导航（‹ 年月 › ✕ 关闭）
            Row {
                width: parent.width; height: 32
                Button {
                    text: "<"; flat: true; width: 32; height: 32
                    background: Rectangle { color: "transparent" }
                    palette.buttonText: root.cText; font.pixelSize: 14
                    onClicked: { if (dateSelector.viewMonth === 0) { dateSelector.viewMonth = 11; dateSelector.viewYear-- } else { dateSelector.viewMonth-- } }
                }
                Text {
                    text: dateSelector.viewYear + root.tt("yearStr") + (dateSelector.viewMonth + 1) + root.tt("monthStr")
                    color: root.cText; font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter; width: parent.width - 96; height: 32
                    verticalAlignment: Text.AlignVCenter
                }
                Button {
                    text: ">"; flat: true; width: 32; height: 32
                    background: Rectangle { color: "transparent" }
                    palette.buttonText: root.cText; font.pixelSize: 14
                    onClicked: { if (dateSelector.viewMonth === 11) { dateSelector.viewMonth = 0; dateSelector.viewYear++ } else { dateSelector.viewMonth++ } }
                }
                // ✕ 关闭按钮（hover 红底白字，与 FramelessDragBar 关闭按钮样式一致）
                Button {
                    id: dateSelectorClose
                    text: "✕"; flat: true; width: 32; height: 32
                    background: Rectangle {
                        color: dateSelectorClose.hovered ? "#ff4444" : "transparent"
                        radius: 6
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    palette.buttonText: dateSelectorClose.hovered ? "#ffffff" : root.cSub
                    onClicked: dateSelector.close()
                }
            }

            // 星期标题行
            Row {
                width: parent.width; height: 20
                Repeater {
                    model: [root.tt("sun"), root.tt("mon"), root.tt("tue"), root.tt("wed"), root.tt("thu"), root.tt("fri"), root.tt("sat")]
                    Text { text: modelData; width: parent.width / 7; horizontalAlignment: Text.AlignHCenter; color: root.cSub; font.pixelSize: 11 }
                }
            }

            // 日期网格
            GridView {
                id: dateGrid
                width: parent.width; height: parent.height - 108
                cellWidth: parent.width / 7; cellHeight: 32
                interactive: false
                clip: true
                model: {
                    var firstDay = new Date(dateSelector.viewYear, dateSelector.viewMonth, 1)
                    var startOffset = firstDay.getDay()
                    var daysInMonth = new Date(dateSelector.viewYear, dateSelector.viewMonth + 1, 0).getDate()
                    var cells = []
                    for (var i = 0; i < startOffset; i++) cells.push(0)
                    for (var d = 1; d <= daysInMonth; d++) cells.push(d)
                    while (cells.length % 7 !== 0) cells.push(0)
                    return cells
                }
                delegate: Rectangle {
                    width: dateGrid.cellWidth; height: dateGrid.cellHeight
                    color: {
                        if (modelData === 0) return "transparent"
                        var cellDate = new Date(dateSelector.viewYear, dateSelector.viewMonth, modelData)
                        var selYMD = root.dateToYMD(dateSelector.selectedDate)
                        var cellYMD = root.dateToYMD(cellDate)
                        return selYMD === cellYMD ? root.cAccent : (dateCellMA.containsMouse ? Qt.rgba(root.cAccent.r, root.cAccent.g, root.cAccent.b, 0.2) : "transparent")
                    }
                    radius: 4
                    visible: modelData !== 0
                    Text {
                        anchors.centerIn: parent
                        text: modelData === 0 ? "" : modelData
                        color: {
                            if (modelData === 0) return "transparent"
                            var cellDate = new Date(dateSelector.viewYear, dateSelector.viewMonth, modelData)
                            var selYMD = root.dateToYMD(dateSelector.selectedDate)
                            var cellYMD = root.dateToYMD(cellDate)
                            return selYMD === cellYMD ? "#ffffff" : root.cText
                        }
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: dateCellMA
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (modelData !== 0) dateSelector.selectedDate = new Date(dateSelector.viewYear, dateSelector.viewMonth, modelData) }
                    }
                }
            }

            // 底部按钮
            Row {
                width: parent.width; spacing: 8
                Button {
                    id: dateClearBtn
                    text: root.tt("clearDate"); flat: true; width: (parent.width - 8) / 2; height: 32
                    background: Rectangle {
                        color: dateClearBtn.hovered ? "#ff4444" : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.1)
                        radius: 4; border.color: dateClearBtn.hovered ? "#ff4444" : root.cBorder; border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                    palette.buttonText: dateClearBtn.hovered ? "#ffffff" : root.cSub; font.pixelSize: 12
                    onClicked: { dateSelector.writeBack(""); dateSelector.close() }
                }
                Button {
                    text: root.tt("confirm"); flat: true; width: (parent.width - 8) / 2; height: 32
                    background: Rectangle { color: root.cAccent; radius: 4 }
                    palette.buttonText: "#ffffff"; font.pixelSize: 12
                    onClicked: {
                        var ymd = root.dateToYMD(dateSelector.selectedDate)
                        dateSelector.writeBack(ymd)
                        dateSelector.close()
                    }
                }
            }
        }
    }

    // ===== 导出格式选择（保留，供文件功能调用）=====
    Window {
        id: exportFormatDialog
        title: tt("exportTitle")
        modality: Qt.WindowModal
        transientParent: fileDialog
        flags: Qt.FramelessWindowHint | Qt.Window
        width: 440; height: 320
        minimumWidth: 400; minimumHeight: 280
        color: "transparent"
        x: root.x + (root.width - width) / 2
        y: root.y + (root.height - height) / 2
        palette.window: cCard; palette.windowText: cText; palette.text: cText; palette.button: cCard; palette.buttonText: cText; palette.base: cInput; palette.placeholderText: cSub; palette.highlight: cAccent; palette.highlightedText: "#ffffff"
        Rectangle { anchors.fill: parent; radius: 8; color: root.cBg }
        FramelessDragBar { dialogWindow: exportFormatDialog }
        Column {
            anchors.fill: parent; anchors.margins: 16; anchors.topMargin: 38; spacing: 10
            Flickable {
                width: parent.width; height: parent.height - 50; clip: true
                contentWidth: width; contentHeight: exportCol.height
                ScrollBar.vertical: MainSB {}
                Column { id: exportCol; spacing: 10; width: parent.width - 32
                    Label { text: tt("exportFormat") + "："; color: cText; font.bold: true; font.pixelSize: 14 }
                    BtnGhost { text: tt("jsonFormat"); width: parent.width; onClicked: { exportFormatDialog.close(); exportDialog.openWith("json"); } }
                    BtnGhost { text: tt("txtFormat"); width: parent.width; onClicked: { exportFormatDialog.close(); exportDialog.openWith("txt"); } }
                    BtnGhost { text: tt("csvFormat"); width: parent.width; onClicked: { exportFormatDialog.close(); exportDialog.openWith("csv"); } }
                }
            }
            Row { width: parent.width; spacing: 8
                Item { width: parent.width - 100; height: 1 }
                BtnCancel { onClicked: exportFormatDialog.close() }
            }
        }
    }
    FileDialog {
        id: exportDialog; title: tt("exportTo"); fileMode: FileDialog.SaveFile
        property string fileSuffix: "json"; defaultSuffix: fileSuffix
        // 打开导出对话框，预设后缀和默认文件名（跟随当前语言）
        function openWith(suffix) {
            fileSuffix = suffix
            // 预设默认文件名（用户可在对话框中修改）
            selectedFile = tt("exportDefaultName") + "." + suffix
            open()
        }
        onAccepted: {
            var p = urlToPath(currentFile);
            var sfx = "." + fileSuffix;
            if (!p.toLowerCase().endsWith(sfx)) p = p + sfx;
            if (fileSuffix==="json") dbManager.exportData(p); else if (fileSuffix==="txt") dbManager.exportTxt(p); else dbManager.exportCsv(p);
        }
    }

    // ===== 导入说明 =====
    Window {
        id: importTipDialog
        title: tt("importTitle")
        modality: Qt.WindowModal
        transientParent: fileDialog
        flags: Qt.FramelessWindowHint | Qt.Window
        width: 480; height: 460
        minimumWidth: 440; minimumHeight: 400
        color: "transparent"
        x: root.x + (root.width - width) / 2
        y: root.y + (root.height - height) / 2
        palette.window: cCard; palette.windowText: cText; palette.text: cText; palette.button: cCard; palette.buttonText: cText; palette.base: cInput; palette.placeholderText: cSub; palette.highlight: cAccent; palette.highlightedText: "#ffffff"
        Rectangle { anchors.fill: parent; radius: 8; color: root.cBg }
        FramelessDragBar { dialogWindow: importTipDialog }
        Flickable {
            anchors.fill: parent; anchors.margins: 12; anchors.topMargin: 38; clip: true; contentWidth: width; contentHeight: importCol.height
            ScrollBar.vertical: MainSB {}
            Column { id: importCol; spacing: 10; width: importTipDialog.width - 48
                Label { width: parent.width; wrapMode: Text.Wrap; color: cText; font.pixelSize: 13; text: tt("importDesc") }
                Label { text: tt("exampleLabel"); color: cText; font.bold: true; font.pixelSize: 13 }
                TextArea { width: parent.width; height: 220; readOnly: true; wrapMode: TextArea.Wrap; font.family: "Consolas"; font.pixelSize: 11; color: cText
                    text:'[\n  {\n    "name": "CLANNAD",\n    "cover_path": "",\n    "types": "[\"校园\",\"恋爱\",\"治愈\"]",\n    "rating": 9.3,\n    "status": "已完成",\n    "play_time": 50,\n    "start_date": "2026-06-01",\n    "finish_date": "2026-07-15",\n    "notes": "非常感人的作品，强烈推荐"\n  },\n  {\n    "name": "Steins;Gate",\n    "cover_path": "",\n    "types": "[\"科幻\",\"悬疑\"]",\n    "rating": 9.8,\n    "status": "已完成",\n    "play_time": 65,\n    "start_date": "2026-05-01",\n    "finish_date": "2026-05-28",\n    "notes": "命运石之门，神作！"\n  }\n]'
                    background: InputBg {}
                }
                Label { width: parent.width; wrapMode: Text.Wrap; color: cSub; font.pixelSize: 11; text: tt("importTip") }
                Row { spacing: 8; anchors.horizontalCenter: parent.horizontalCenter
                    BtnImport { text: tt("selectFileToImport"); onClicked: { importTipDialog.close(); importDialog.open(); } }
                    BtnCancel { onClicked: importTipDialog.close() }
                }
            }
        }
    }
    FileDialog { id: importDialog; title: tt("importFrom"); fileMode: FileDialog.OpenFile; nameFilters: ["JSON 文件 (*.json)"]
        onAccepted: { dbManager.importData(urlToPath(currentFile)); gameListModel.refresh(searchField.text); refreshStats(); } }

    // ===== 设置窗口（Window 形式）=====
    Window {
        id: fileDialog
        title: tt("fileBtn")
        modality: Qt.WindowModal
        flags: Qt.FramelessWindowHint | Qt.Window
        width: 400; height: 400
        minimumWidth: 380; minimumHeight: 360
        color: "transparent"
        x: root.x + (root.width - width) / 2
        y: root.y + (root.height - height) / 2
        palette.window: cCard; palette.windowText: cText; palette.text: cText; palette.button: cCard; palette.buttonText: cText; palette.base: cInput; palette.placeholderText: cSub; palette.highlight: cAccent; palette.highlightedText: "#ffffff"
        Rectangle { anchors.fill: parent; radius: 8; color: root.cBg }
        FramelessDragBar { dialogWindow: fileDialog }
        Column {
            anchors.fill: parent; anchors.margins: 16; anchors.topMargin: 38; spacing: 12
            Flickable {
                width: parent.width; height: parent.height - 50; clip: true
                contentWidth: width; contentHeight: settingsCol.height
                ScrollBar.vertical: MainSB {}
                Column { id: settingsCol; width: parent.width; spacing: 14
                    // 文档功能（导出/导入）
                    Label { text: tt("fileBtn"); color: cText; font.pixelSize: 14; width: parent.width }
                    Column { width: parent.width; spacing: 6; leftPadding: 12
                        BtnGhost { text: tt("jsonFormat"); width: parent.width - 12; onClicked: { fileDialog.close(); exportDialog.openWith("json"); } }
                        BtnGhost { text: tt("txtFormat"); width: parent.width - 12; onClicked: { fileDialog.close(); exportDialog.openWith("txt"); } }
                        BtnGhost { text: tt("csvFormat"); width: parent.width - 12; onClicked: { fileDialog.close(); exportDialog.openWith("csv"); } }
                        BtnGhost { text: tt("selectFileToImport"); width: parent.width - 12; onClicked: { fileDialog.close(); importTipDialog.show(); } }
                    }
                    // 回忆根目录设置
                    Column { width: parent.width; spacing: 6
                        Label { text: "📸 " + tt("memoryRoot"); color: cText; font.pixelSize: 14 }
                        Row { width: parent.width; spacing: 8
                            TextField {
                                id: memoryRootField; width: parent.width - 100; readOnly: true
                                placeholderText: tt("memoryRootNotSet"); text: dbManager.getMemoryRoot()
                                background: InputBg {}
                            }
                            BtnGhost { text: tt("selectFolder"); width: 92; onClicked: memoryRootDialog.open() }
                        }
                    }
                }
            }
            Row { width: parent.width; spacing: 8
                Item { width: parent.width - 100; height: 1 }
                BtnClose { text: tt("close"); onClicked: fileDialog.close() }
            }
        }
        onVisibleChanged: if (visible) memoryRootField.text = dbManager.getMemoryRoot()
    }
    FolderDialog {
        id: memoryRootDialog; title: tt("selectFolder")
        onAccepted: { var p = urlToPath(currentFolder); dbManager.setMemoryRoot(p); memoryRootField.text = p; }
    }
    // ===== 外观设置窗口（子 Window）=====
    Window {
        id: appearanceDialog
        title: tt("appearance")
        modality: Qt.WindowModal
        transientParent: root
        flags: Qt.FramelessWindowHint | Qt.Window
        width: 620; height: 540
        minimumWidth: 560; minimumHeight: 480
        color: "transparent"
        x: root.x + (root.width - width) / 2
        y: root.y + (root.height - height) / 2
        palette.window: cCard; palette.windowText: cText; palette.text: cText; palette.button: cCard; palette.buttonText: cText; palette.base: cInput; palette.placeholderText: cSub; palette.highlight: cAccent; palette.highlightedText: "#ffffff"
        Rectangle { anchors.fill: parent; radius: 8; color: root.cBg }
        FramelessDragBar { dialogWindow: appearanceDialog }
        Column {
            anchors.fill: parent; anchors.margins: 15; anchors.topMargin: 38; spacing: 10
            Flickable {
                width: parent.width; height: parent.height - 50; clip: true
                contentWidth: width; contentHeight: appearCol.height
                ScrollBar.vertical: MainSB {}
                Column { id: appearCol; width: parent.width - 30; spacing: 14
                    Label { text: tt("themeColor"); font.bold: true; color: cText; font.pixelSize: 14 }
                    Row { spacing: 8; Repeater {
                        model: [{key:"blue",color:"#3a9fff",nameKey:"cBlue"},{key:"green",color:"#3fb958",nameKey:"cGreen"},{key:"yellow",color:"#f0b400",nameKey:"cYellow"},{key:"pink",color:"#ff7aa8",nameKey:"cPink"},{key:"black",color:"#3a3a3a",nameKey:"cBlack"},{key:"gray",color:"#888888",nameKey:"cGray"},{key:"white",color:"#bbbbbb",nameKey:"cWhite"}]
                        delegate: Rectangle { width:44; height:44; radius:8; color:modelData.color; border.width:root.currentTheme===modelData.key?3:1; border.color:root.currentTheme===modelData.key?cAccent:cBorder
                            MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:root.currentTheme=modelData.key}
                            Label{anchors.bottom:parent.bottom;anchors.bottomMargin:2;anchors.horizontalCenter:parent.horizontalCenter;text:tt(modelData.nameKey);color:"white";font.pixelSize:10}
                        }
                    }}
                    Rectangle {
                        width: parent.width; radius: 8; border.width: 1; border.color: cBorder
                        color: Qt.rgba(cText.r, cText.g, cText.b, 0.03)
                        height: 48
                        Row { anchors.fill: parent; anchors.margins: 10; spacing: 8
                            Label { text: tt("customMode"); font.bold: true; color: isDark ? cSub : cText; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                            Item { width: parent.width - 100 - 60 - (isDark ? 100 : 0); height: 1 }
                            Label { visible: isDark; text: tt("customDisabledDark"); color: cSub; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                            Switch { id: customSwitch; enabled: !isDark; checked: root.currentTheme === "custom"; onToggled: {
                                if (checked) { root.preCustomTheme = root.currentTheme; root.currentTheme = "custom" }
                                else { root.currentTheme = root.preCustomTheme }
                            }
                                Connections { target: root; function onCurrentThemeChanged() { customSwitch.checked = (root.currentTheme === "custom") } }
                            }
                        }
                    }
                    Rectangle {
                        width: parent.width; radius: 8; border.width: root.currentTheme === "custom" ? 2 : 1
                        border.color: root.currentTheme === "custom" ? cAccent : cBorder
                        color: root.currentTheme === "custom" ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.06) : Qt.rgba(cText.r, cText.g, cText.b, 0.03)
                        visible: root.currentTheme === "custom"
                        height: root.currentTheme === "custom" ? customCol.height + 20 : 0
                        Column { id: customCol; width: parent.width - 20; x: 10; y: 10; spacing: 12
                            Label { text: tt("accentColor"); color: cSub; font.pixelSize: 12 }
                            Row { width: parent.width; spacing: 8
                                Rectangle { width: 40; height: 40; radius: 8; color: root.customAccent; border.color: cBorder; border.width: 1; anchors.verticalCenter: parent.verticalCenter
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: customAccentDialog.show() }
                                }
                                TextField { id: customAccentHex; width: parent.width - 40 - 8; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                                    text: root.customAccent.toString().toUpperCase()
                                    onEditingFinished: { var t = text.trim(); if (/^#[0-9a-fA-F]{6}$/.test(t) || /^#[0-9a-fA-F]{8}$/.test(t)) root.customAccent = t; else text = root.customAccent.toString().toUpperCase(); }
                                    background: InputBg {}
                                }
                            }
                            Flow { width: parent.width; spacing: 6
                                Repeater {
                                    model: ["#ff4444", "#ff8844", "#ffc94d", "#5bd06d", "#27d2bf", "#3a9fff", "#9b5de5", "#ff7aa8", "#3a3a3a", "#888888"]
                                    delegate: Rectangle { width: 28; height: 28; radius: 6; color: modelData; border.width: root.customAccent.toString().toLowerCase() === modelData.toLowerCase() ? 3 : 1; border.color: root.customAccent.toString().toLowerCase() === modelData.toLowerCase() ? cAccent : cBorder
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.customAccent = modelData } }
                                }
                            }
                            Label { text: tt("bgColor"); color: cSub; font.pixelSize: 12 }
                            Row { width: parent.width; spacing: 8
                                Rectangle { width: 40; height: 40; radius: 8; color: root.customBgColor; border.color: cBorder; border.width: 1; anchors.verticalCenter: parent.verticalCenter
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: customBgColorDialog.show() }
                                }
                                TextField { id: customBgHex; width: parent.width - 40 - 8; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                                    text: root.customBgColor.toString().toUpperCase()
                                    onEditingFinished: { var t = text.trim(); if (/^#[0-9a-fA-F]{6}$/.test(t) || /^#[0-9a-fA-F]{8}$/.test(t)) root.customBgColor = t; else text = root.customBgColor.toString().toLowerCase(); }
                                    background: InputBg {}
                                }
                            }
                            Flow { width: parent.width; spacing: 6
                                Repeater {
                                    model: ["#f5f5f8", "#e8f0fe", "#e6f4ea", "#fef7e0", "#fce4ec", "#f0f0f0", "#1a1a24", "#0d1b2a", "#0d1f12", "#1f0d14"]
                                    delegate: Rectangle { width: 28; height: 28; radius: 6; color: modelData; border.width: root.customBgColor.toString().toLowerCase() === modelData.toLowerCase() ? 3 : 1; border.color: root.customBgColor.toString().toLowerCase() === modelData.toLowerCase() ? cAccent : cBorder
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.customBgColor = modelData } }
                                }
                            }
                            Label { text: tt("clickToSelect"); color: cSub; font.pixelSize: 10; width: parent.width; wrapMode: Text.Wrap }
                            // ===== 自定义文本颜色（与 accentColor/bgColor 同级，采用背景模式：色板+hex+常驻预设色块）=====
                            Label { text: tt("textColor"); color: cSub; font.pixelSize: 12 }
                            // 主文本色
                            Label { text: tt("mainTextColor"); color: cSub; font.pixelSize: 12 }
                            Row { width: parent.width; spacing: 8
                                Rectangle { width: 40; height: 40; radius: 8; color: root.customTextColor; border.color: cBorder; border.width: 1; anchors.verticalCenter: parent.verticalCenter
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: customTextColorDialog.show() }
                                }
                                TextField { id: customTextHex; width: parent.width - 40 - 8; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                                    text: root.customTextColor.toString().toUpperCase()
                                    onEditingFinished: { var t = text.trim(); if (/^#[0-9a-fA-F]{6}$/.test(t) || /^#[0-9a-fA-F]{8}$/.test(t)) { root.customTextColor = t; root.customTextColorSet = true; } else text = root.customTextColor.toString().toUpperCase(); }
                                    background: InputBg {}
                                }
                            }
                            Flow { width: parent.width; spacing: 6
                                Repeater {
                                    model: ["#222222", "#444444", "#666666", "#1a3a5c", "#5c1a3a", "#3a5c1a", "#5c3a1a", "#e8e8ec", "#ffffff", "#ffd700"]
                                    delegate: Rectangle { width: 28; height: 28; radius: 6; color: modelData; border.width: root.customTextColor.toString().toLowerCase() === modelData.toLowerCase() ? 3 : 1; border.color: root.customTextColor.toString().toLowerCase() === modelData.toLowerCase() ? cAccent : cBorder
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.customTextColor = modelData; root.customTextColorSet = true; } } }
                                }
                            }
                            // 次要文本色
                            Label { text: tt("subTextColor"); color: cSub; font.pixelSize: 12 }
                            Row { width: parent.width; spacing: 8
                                Rectangle { width: 40; height: 40; radius: 8; color: root.customSubColor; border.color: cBorder; border.width: 1; anchors.verticalCenter: parent.verticalCenter
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: customSubColorDialog.show() }
                                }
                                TextField { id: customSubHex; width: parent.width - 40 - 8; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                                    text: root.customSubColor.toString().toUpperCase()
                                    onEditingFinished: { var t = text.trim(); if (/^#[0-9a-fA-F]{6}$/.test(t) || /^#[0-9a-fA-F]{8}$/.test(t)) { root.customSubColor = t; root.customSubColorSet = true; } else text = root.customSubColor.toString().toUpperCase(); }
                                    background: InputBg {}
                                }
                            }
                            Flow { width: parent.width; spacing: 6
                                Repeater {
                                    model: ["#666666", "#888888", "#9999aa", "#4a6a8a", "#8a4a6a", "#4a8a6a", "#8a6a4a", "#bbbbbb", "#cccccc", "#ff9966"]
                                    delegate: Rectangle { width: 28; height: 28; radius: 6; color: modelData; border.width: root.customSubColor.toString().toLowerCase() === modelData.toLowerCase() ? 3 : 1; border.color: root.customSubColor.toString().toLowerCase() === modelData.toLowerCase() ? cAccent : cBorder
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.customSubColor = modelData; root.customSubColorSet = true; } } }
                                }
                            }
                        }
                    }
                    Label { text: tt("bgImage"); font.bold: true; color: cText; font.pixelSize: 14 }
                    Row { spacing: 8
                        BtnGhost { text: tt("selectImage"); onClicked: bgImageDialog.open() }
                        BtnGhost { text: tt("bgHistoryBtn"); onClicked: { bgHistoryDialog.refresh(); bgHistoryDialog.show() } }
                        Button {
                            id: clearBgBtn; text: tt("clearBg"); flat: true
                            background: Rectangle { color: clearBgBtn.hovered ? "#ff4444" : "#30ff4444"; radius: 8; border.color: "#ff4444"; border.width: 1; implicitWidth: 100; implicitHeight: 34; Behavior on color { ColorAnimation { duration: 150 } } }
                            palette.buttonText: clearBgBtn.hovered ? "#ffffff" : "#ff4444"
                            onClicked: { root.bgImagePath = ""; root.currentBgHistoryId = -1 }
                        }
                    }
                    Label { text: tt("bgOpacity") + "：" + Math.round(root.bgOpacity*100)+"%"; color: cText; font.pixelSize: 12
                        visible: !(root.bgImagePath.length > 0 && isVideoFile(root.bgImagePath)) }
                    RoundSlider { from:0; to:1; value:root.bgOpacity; onMoved:root.bgOpacity=value; width:parent.width
                        visible: !(root.bgImagePath.length > 0 && isVideoFile(root.bgImagePath)) }
                    Label { text: tt("bgBlur") + "：" + Math.round(root.bgBlur*100)+"%"; color: cText; font.pixelSize: 12
                        visible: !(root.bgImagePath.length > 0 && isVideoFile(root.bgImagePath)) }
                    RoundSlider { from:0; to:1; value:root.bgBlur; onMoved:root.bgBlur=value; width:parent.width
                        visible: !(root.bgImagePath.length > 0 && isVideoFile(root.bgImagePath)) }
                }
            }
            Row { width: parent.width; spacing: 8
                Item { width: parent.width - 100; height: 1 }
                BtnClose { text: tt("close"); onClicked: appearanceDialog.close() }
            }
        }
    }

    // ===== 背景图片历史窗口（子 Window）=====
    Window {
        id: bgHistoryDialog
        title: tt("bgHistory")
        modality: Qt.WindowModal
        transientParent: appearanceDialog
        flags: Qt.FramelessWindowHint | Qt.Window
        width: 540; height: 480
        minimumWidth: 500; minimumHeight: 400
        color: "transparent"
        x: root.x + (root.width - width) / 2
        y: root.y + (root.height - height) / 2
        palette.window: cCard; palette.windowText: cText; palette.text: cText; palette.button: cCard; palette.buttonText: cText; palette.base: cInput; palette.placeholderText: cSub; palette.highlight: cAccent; palette.highlightedText: "#ffffff"
        property var images: []
        function refresh() { images = dbManager.getBgImages() }
        Rectangle { anchors.fill: parent; radius: 8; color: root.cBg }
        FramelessDragBar { dialogWindow: bgHistoryDialog }
        Flickable {
            anchors.fill: parent; anchors.margins: 12; anchors.topMargin: 38; anchors.bottomMargin: 52
            clip: true; contentWidth: width; contentHeight: height
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: MainSB {}
            ColumnLayout {
                id: bgHistCol
                width: parent.width; height: parent.height; spacing: 8
                ListView {
                    id: bgHistoryList; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 8; model: bgHistoryDialog.images
                    ScrollBar.vertical: MainSB {}
                    delegate: Rectangle {
                        width: bgHistoryList.width; height: 90; radius: 8
                        color: Qt.rgba(cCard.r, cCard.g, cCard.b, 0.7); border.color: cBorder; border.width: 1
                        Row {
                            anchors.fill: parent; anchors.margins: 8; spacing: 10
                            Rectangle {
                                width: 96; height: 74; radius: 6; color: cBorder; clip: true
                                Image { anchors.fill: parent; visible: !isVideoFile(modelData.imagePath); source: modelData.imagePath.length > 0 ? "file:///" + modelData.imagePath.replace(/\\/g, "/") : ""; fillMode: Image.PreserveAspectCrop }
                                // 视频文件占位符
                                Rectangle { anchors.fill: parent; visible: isVideoFile(modelData.imagePath); color: "#1a1a1a"
                                    Text { anchors.centerIn: parent; text: "▶ MP4"; color: "#ffffff"; font.pixelSize: 14; font.bold: true }
                                }
                            }
                            Column {
                                width: parent.width - 96 - 10; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                                Text { width: parent.width; text: modelData.imagePath.split("/").pop().split("\\").pop(); font.pixelSize: 13; color: cText; elide: Text.ElideRight }
                                Text { text: modelData.createdAt; font.pixelSize: 11; color: cSub }
                                Text { text: tt("bgOpacity") + " " + Math.round(modelData.opacity * 100) + "%   " + tt("bgBlur") + " " + Math.round(modelData.blur * 100) + "%"; font.pixelSize: 11; color: cSub; visible: !isVideoFile(modelData.imagePath) }
                                Row {
                                    spacing: 6; topPadding: 2
                                    BtnGhost { text: tt("useFull"); implicitHeight: 26; onClicked: { root.currentBgHistoryId = modelData.id; root.bgImagePath = modelData.imagePath; root.bgOpacity = modelData.opacity; root.bgBlur = modelData.blur; bgHistoryDialog.close() } }
                                    BtnGhost { text: tt("cropBtn"); visible: !isVideoFile(modelData.imagePath); implicitHeight: 26; onClicked: { cropDialog.openBg(modelData.imagePath) } }
                                    Button { text: tt("del"); flat: true; implicitHeight: 26; font.pixelSize: 12
                                        palette.buttonText: "#ff6666"
                                        background: Rectangle { color: "#30ff4444"; radius: 6; border.color: "#ff4444"; border.width: 1 }
                                        onClicked: { deleteBgDialog.targetId = modelData.id; deleteBgDialog.targetPath = modelData.imagePath; deleteBgDialog.show() } }
                                }
                            }
                        }
                    }
                    Label { anchors.centerIn: parent; visible: bgHistoryList.count === 0; text: tt("noCover"); color: cSub }
                }
            }
        }
        Row {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.margins: 12; spacing: 8
            Item { width: parent.width - 100; height: 1 }
            BtnClose { text: tt("close"); onClicked: bgHistoryDialog.close() }
        }
        onVisibleChanged: if (visible) refresh()
    }

    // ===== 背景图编辑窗口（带效果预览，整合使用+裁剪+删除）=====
    Window {
        id: editBgDialog
        title: tt("editBg")
        modality: Qt.WindowModal
        transientParent: bgHistoryDialog
        flags: Qt.FramelessWindowHint | Qt.Window
        width: 580; height: 560
        minimumWidth: 540; minimumHeight: 500
        color: "transparent"
        x: root.x + (root.width - width) / 2
        y: root.y + (root.height - height) / 2
        palette.window: cCard; palette.windowText: cText; palette.text: cText; palette.button: cCard; palette.buttonText: cText; palette.base: cInput; palette.placeholderText: cSub; palette.highlight: cAccent; palette.highlightedText: "#ffffff"
        property int targetId: -1
        property string imagePath: ""
        property real editOpacity: 0.35
        property real editBlur: 0.5
        function openWith(id, path, op, bl) {
            targetId = id; imagePath = path; editOpacity = op; editBlur = bl; show();
        }
        Rectangle { anchors.fill: parent; radius: 8; color: root.cBg }
        FramelessDragBar { dialogWindow: editBgDialog }
        Column {
            anchors.fill: parent; anchors.margins: 12; anchors.topMargin: 38; spacing: 10
            Flickable {
                width: parent.width; height: parent.height - 60; clip: true
                contentWidth: width; contentHeight: editBgCol.height
                ScrollBar.vertical: MainSB {}
                Column { id: editBgCol;
                    width: parent.width - 24; spacing: 10
                    Label { text: tt("effectPreview"); font.bold: true; color: cText; font.pixelSize: 13 }
                    Rectangle {
                        width: parent.width; height: 280; radius: 8; color: effDark ? "#1a1a24" : "#f5f5f8"; clip: true; border.color: cBorder; border.width: 1
                        Image {
                            anchors.fill: parent; visible: editBgDialog.imagePath.length > 0 && !editBgDialog.imagePath.toLowerCase().endsWith(".gif")
                            source: visible ? "file:///" + editBgDialog.imagePath.replace(/\\/g, "/") : ""
                            fillMode: Image.PreserveAspectCrop; opacity: editBgDialog.editOpacity
                            layer.enabled: editBgDialog.editBlur > 0 && visible
                            layer.effect: MultiEffect { blurEnabled: true; blur: editBgDialog.editBlur; blurMax: 64 }
                        }
                        AnimatedImage {
                            anchors.fill: parent; visible: editBgDialog.imagePath.length > 0 && editBgDialog.imagePath.toLowerCase().endsWith(".gif")
                            source: visible ? "file:///" + editBgDialog.imagePath.replace(/\\/g, "/") : ""
                            fillMode: Image.PreserveAspectCrop; opacity: editBgDialog.editOpacity
                            layer.enabled: editBgDialog.editBlur > 0 && visible
                            layer.effect: MultiEffect { blurEnabled: true; blur: editBgDialog.editBlur; blurMax: 64 }
                        }
                    }
                    Row {
                        width: parent.width; spacing: 8
                        Label { text: tt("bgOpacity"); color: cText; font.pixelSize: 13; width: 60; anchors.verticalCenter: parent.verticalCenter }
                        RoundSlider { from: 0; to: 1; value: editBgDialog.editOpacity; onMoved: editBgDialog.editOpacity = value; width: parent.width - 60 - 50 }
                        Label { text: Math.round(editBgDialog.editOpacity * 100) + "%"; color: cSub; font.pixelSize: 12; width: 50; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Row {
                        width: parent.width; spacing: 8
                        Label { text: tt("bgBlur"); color: cText; font.pixelSize: 13; width: 60; anchors.verticalCenter: parent.verticalCenter }
                        RoundSlider { from: 0; to: 1; value: editBgDialog.editBlur; onMoved: editBgDialog.editBlur = value; width: parent.width - 60 - 50 }
                        Label { text: Math.round(editBgDialog.editBlur * 100) + "%"; color: cSub; font.pixelSize: 12; width: 50; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Label { text: tt("dragToMove"); color: cSub; font.pixelSize: 11 }
                }
            }
            // 操作按钮行（保存+取消）
            Row {
                width: parent.width; spacing: 8
                Item { width: parent.width - 180; height: 1 }
                BtnCancel { onClicked: editBgDialog.close() }
                BtnSave {
                    onClicked: {
                        dbManager.updateBgImage(editBgDialog.targetId, editBgDialog.editOpacity, editBgDialog.editBlur);
                        if (root.bgImagePath === editBgDialog.imagePath) {
                            root.bgOpacity = editBgDialog.editOpacity;
                            root.bgBlur = editBgDialog.editBlur;
                        }
                        bgHistoryDialog.refresh();
                        editBgDialog.close();
                    }
                }
            }
        }
    }

    // ===== 删除背景图确认窗口 =====
    Window {
        id: deleteBgDialog
        title: tt("deleteBg")
        modality: Qt.WindowModal
        transientParent: bgHistoryDialog
        flags: Qt.FramelessWindowHint | Qt.Window
        width: 340; height: 160
        minimumWidth: 320; minimumHeight: 140
        color: "transparent"
        x: root.x + (root.width - width) / 2
        y: root.y + (root.height - height) / 2
        palette.window: cCard; palette.windowText: cText; palette.text: cText; palette.button: cCard; palette.buttonText: cText; palette.base: cInput; palette.placeholderText: cSub; palette.highlight: cAccent; palette.highlightedText: "#ffffff"
        property int targetId: -1; property string targetPath: ""
        property bool accepted: false
        Rectangle { anchors.fill: parent; radius: 8; color: root.cBg }
        FramelessDragBar { dialogWindow: deleteBgDialog }
        Column {
            anchors.fill: parent; anchors.margins: 16; anchors.topMargin: 38; spacing: 12
            Label { text: tt("deleteConfirm", tt("bgImage")); color: cText; width: parent.width; wrapMode: Text.Wrap }
            Row { width: parent.width; spacing: 8
                Item { width: parent.width - 180; height: 1 }
                BtnCancel { onClicked: { deleteBgDialog.accepted = false; deleteBgDialog.close() } }
                BtnOk { onClicked: {
                    deleteBgDialog.accepted = true
                    if (root.bgImagePath === deleteBgDialog.targetPath) { root.bgImagePath = ""; root.currentBgHistoryId = -1 }
                    dbManager.deleteBgImage(deleteBgDialog.targetId);
                    bgHistoryDialog.refresh();
                    deleteBgDialog.close();
                } }
            }
        }
    }

    // ===== 背景裁剪对话框 =====
    Window {
        id: cropDialog
        title: cropDialog.mode === "cover" || cropDialog.mode === "coverDetail" ? tt("coverCrop") : tt("crop")
        modality: Qt.WindowModal
        flags: Qt.FramelessWindowHint | Qt.Window
        transientParent: cropDialog.mode === "cover" ? editDialog
                        : cropDialog.mode === "coverDetail" ? gameDetailDialog
                        : cropDialog.mode === "bg" ? (bgHistoryDialog.visible ? bgHistoryDialog : (appearanceDialog.visible ? appearanceDialog : root))
                        : root
        width: 640; height: 560
        minimumWidth: 600; minimumHeight: 520
        color: "transparent"
        x: root.x + (root.width - width) / 2
        y: root.y + (root.height - height) / 2
        palette.window: cCard; palette.windowText: cText; palette.text: cText; palette.button: cCard; palette.buttonText: cText; palette.base: cInput; palette.placeholderText: cSub; palette.highlight: cAccent; palette.highlightedText: "#ffffff"
        property string sourcePath: ""
        property string mode: "bg"   // "bg" 背景裁剪 / "cover" 封面裁剪 / "coverDetail" 详情页封面裁剪
        property real dispX: 0; property real dispY: 0; property real dispW: 0; property real dispH: 0
        property real scaleX: 1; property real scaleY: 1
        property real selX: 0; property real selY: 0; property real selW: 0; property real selH: 0

        function openWith(src) { sourcePath = src; selX = 0; selY = 0; selW = 0; selH = 0; show(); if (imagePreview.status === Image.Ready) calcLayout(); }
        function openCover(src) { mode = "cover"; openWith(src) }
        function openCoverForDetail(src) { mode = "coverDetail"; openWith(src) }
        function openBg(src) { mode = "bg"; openWith(src) }
        function calcLayout() {
            var cw = cropContainer.width, ch = cropContainer.height;
            var nw = imagePreview.sourceSize.width, nh = imagePreview.sourceSize.height;
            if (nw === 0 || nh === 0) return;
            var s = Math.min(cw / nw, ch / nh);
            dispW = nw * s; dispH = nh * s; dispX = (cw - dispW) / 2; dispY = (ch - dispH) / 2;
            scaleX = nw / dispW; scaleY = nh / dispH;
            var sw = dispW * 0.55, sh = sw * nh / nw;
            if (sh > dispH * 0.85) { sh = dispH * 0.85; sw = sh * nw / nh; }
            selW = sw; selH = sh; selX = dispX + (dispW - sw) / 2; selY = dispY + (dispH - sh) / 2;
        }
        function doCrop() {
            var cx = Math.round((selX - dispX) * scaleX), cy = Math.round((selY - dispY) * scaleY);
            var cw = Math.round(selW * scaleX), ch = Math.round(selH * scaleY);
            var result = dbManager.cropImage(sourcePath, cx, cy, cw, ch);
            if (result.length > 0) {
                if (cropDialog.mode === "cover") {
                    // 封面裁剪：导入裁剪结果到封面目录，更新编辑对话框的封面路径
                    var coverPath = dbManager.importCover(result);
                    editCoverPath.text = coverPath;
                } else if (cropDialog.mode === "coverDetail") {
                    // 详情页封面裁剪：导入裁剪结果到封面目录，更新详情页封面
                    var coverPath2 = dbManager.importCover(result);
                    dbManager.updateGame(gameDetailDialog.detailGameId, gameDetailDialog.detailGameName, gameDetailDialog.detailGameTypes,
                        gameDetailDialog.detailGameRating, gameDetailDialog.detailGameStatus, 0,
                        gameDetailDialog.detailGameStartDate, gameDetailDialog.detailGameFinishDate, gameDetailDialog.detailGameNotes, coverPath2);
                    gameDetailDialog.detailGameCover = coverPath2;
                    gameListModel.refresh(searchField.text);
                } else {
                    // 背景裁剪
                    root.bgImagePath = result; root.currentBgHistoryId = -1; dbManager.addBgImage(result, root.bgOpacity, root.bgBlur);
                }
            }
            close();
        }

        Rectangle { anchors.fill: parent; radius: 8; color: root.cBg }
        FramelessDragBar { dialogWindow: cropDialog }
        Column {
            anchors.fill: parent; anchors.margins: 12; anchors.topMargin: 38; spacing: 12
            Rectangle {
                id: cropContainer; width: parent.width; height: 380; color: "black"; clip: true
                Image { id: imagePreview; anchors.centerIn: parent; width: parent.width; height: parent.height; fillMode: Image.PreserveAspectFit; source: cropDialog.sourcePath.length > 0 ? "file:///" + cropDialog.sourcePath.replace(/\\/g, "/") : ""; onStatusChanged: if (status === Image.Ready) cropDialog.calcLayout() }
                // 四个遮罩区域
                Rectangle { color: "#80000000"; x: 0; y: 0; width: cropContainer.width; height: cropDialog.selY; visible: cropDialog.selW > 0 }
                Rectangle { color: "#80000000"; x: 0; y: cropDialog.selY + cropDialog.selH; width: cropContainer.width; height: cropContainer.height - cropDialog.selY - cropDialog.selH; visible: cropDialog.selW > 0 }
                Rectangle { color: "#80000000"; x: 0; y: cropDialog.selY; width: cropDialog.selX; height: cropDialog.selH; visible: cropDialog.selW > 0 }
                Rectangle { color: "#80000000"; x: cropDialog.selX + cropDialog.selW; y: cropDialog.selY; width: cropContainer.width - cropDialog.selX - cropDialog.selW; height: cropDialog.selH; visible: cropDialog.selW > 0 }

                Rectangle {
                    id: selRect; x: cropDialog.selX; y: cropDialog.selY; width: cropDialog.selW; height: cropDialog.selH
                    color: "transparent"; border.color: "white"; border.width: 2; visible: cropDialog.selW > 0

                    function applySel(nx, ny, nw, nh) {
                        nw = Math.max(40, nw); nh = Math.max(40, nh);
                        if (nx < cropDialog.dispX) { nw -= (cropDialog.dispX - nx); nx = cropDialog.dispX; }
                        if (ny < cropDialog.dispY) { nh -= (cropDialog.dispY - ny); ny = cropDialog.dispY; }
                        if (nx + nw > cropDialog.dispX + cropDialog.dispW) nw = cropDialog.dispX + cropDialog.dispW - nx;
                        if (ny + nh > cropDialog.dispY + cropDialog.dispH) nh = cropDialog.dispY + cropDialog.dispH - ny;
                        nw = Math.max(40, nw); nh = Math.max(40, nh);
                        cropDialog.selX = nx; cropDialog.selY = ny; cropDialog.selW = nw; cropDialog.selH = nh;
                        selRect.x = nx; selRect.y = ny; selRect.width = nw; selRect.height = nh;
                    }

                    // 拖拽移动
                    MouseArea {
                        anchors.fill: parent; anchors.margins: 10; drag.target: selRect
                        drag.minimumX: cropDialog.dispX; drag.maximumX: cropDialog.dispX + cropDialog.dispW - cropDialog.selW
                        drag.minimumY: cropDialog.dispY; drag.maximumY: cropDialog.dispY + cropDialog.dispH - cropDialog.selH
                        cursorShape: Qt.OpenHandCursor
                        onPositionChanged: { cropDialog.selX = selRect.x; cropDialog.selY = selRect.y; }
                    }
                    // 四角手柄
                    Rectangle { x: -5; y: -5; width: 10; height: 10; radius: 5; color: "white"; border.color: "#ff4444"; border.width: 2; z: 2 }
                    Rectangle { anchors.right: parent.right; anchors.rightMargin: -5; y: -5; width: 10; height: 10; radius: 5; color: "white"; border.color: "#ff4444"; border.width: 2; z: 2 }
                    Rectangle { x: -5; anchors.bottom: parent.bottom; anchors.bottomMargin: -5; width: 10; height: 10; radius: 5; color: "white"; border.color: "#ff4444"; border.width: 2; z: 2 }
                    Rectangle { anchors.right: parent.right; anchors.rightMargin: -5; anchors.bottom: parent.bottom; anchors.bottomMargin: -5; width: 10; height: 10; radius: 5; color: "white"; border.color: "#ff4444"; border.width: 2; z: 2 }
                    // 四边手柄
                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: -4; width: 14; height: 8; radius: 3; color: "white"; border.color: "#ff4444"; border.width: 1; z: 2 }
                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: -4; width: 14; height: 8; radius: 3; color: "white"; border.color: "#ff4444"; border.width: 1; z: 2 }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; x: -4; width: 8; height: 14; radius: 3; color: "white"; border.color: "#ff4444"; border.width: 1; z: 2 }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: -4; width: 8; height: 14; radius: 3; color: "white"; border.color: "#ff4444"; border.width: 1; z: 2 }

                    // 左上角缩放
                    MouseArea { width: 24; height: 24; x: -12; y: -12; z: 10; cursorShape: Qt.SizeFDiagCursor
                        property real sx; property real sy; property real ox; property real oy; property real ow; property real oh
                        onPressedChanged: { if (pressed) { sx = mouseX; sy = mouseY; ox = cropDialog.selX; oy = cropDialog.selY; ow = cropDialog.selW; oh = cropDialog.selH; } }
                        onPositionChanged: { var nw = ow - (mouseX - sx), nh = oh - (mouseY - sy); selRect.applySel(ox + ow - nw, oy + oh - nh, nw, nh); }
                    }
                    // 右上角缩放
                    MouseArea { width: 24; height: 24; x: parent.width - 12; y: -12; z: 10; cursorShape: Qt.SizeBDiagCursor
                        property real sx; property real sy; property real ox; property real oy; property real ow; property real oh
                        onPressedChanged: { if (pressed) { sx = mouseX; sy = mouseY; ox = cropDialog.selX; oy = cropDialog.selY; ow = cropDialog.selW; oh = cropDialog.selH; } }
                        onPositionChanged: { var nw = ow + (mouseX - sx), nh = oh - (mouseY - sy); selRect.applySel(ox, oy + oh - nh, nw, nh); }
                    }
                    // 左下角缩放
                    MouseArea { width: 24; height: 24; x: -12; y: parent.height - 12; z: 10; cursorShape: Qt.SizeBDiagCursor
                        property real sx; property real sy; property real ox; property real oy; property real ow; property real oh
                        onPressedChanged: { if (pressed) { sx = mouseX; sy = mouseY; ox = cropDialog.selX; oy = cropDialog.selY; ow = cropDialog.selW; oh = cropDialog.selH; } }
                        onPositionChanged: { var nw = ow - (mouseX - sx), nh = oh + (mouseY - sy); selRect.applySel(ox + ow - nw, oy, nw, nh); }
                    }
                    // 右下角缩放
                    MouseArea { width: 24; height: 24; x: parent.width - 12; y: parent.height - 12; z: 10; cursorShape: Qt.SizeFDiagCursor
                        property real sx; property real sy; property real ox; property real oy; property real ow; property real oh
                        onPressedChanged: { if (pressed) { sx = mouseX; sy = mouseY; ox = cropDialog.selX; oy = cropDialog.selY; ow = cropDialog.selW; oh = cropDialog.selH; } }
                        onPositionChanged: { var nw = ow + (mouseX - sx), nh = oh + (mouseY - sy); selRect.applySel(ox, oy, nw, nh); }
                    }
                    // 上边缩放
                    MouseArea { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; width: 40; height: 12; anchors.topMargin: -6; z: 10; cursorShape: Qt.SizeVerCursor
                        property real sy; property real oy; property real oh
                        onPressedChanged: { if (pressed) { sy = mouseY; oy = cropDialog.selY; oh = cropDialog.selH; } }
                        onPositionChanged: { var nh = oh - (mouseY - sy); selRect.applySel(cropDialog.selX, oy + oh - nh, cropDialog.selW, nh); }
                    }
                    // 下边缩放
                    MouseArea { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: 40; height: 12; anchors.bottomMargin: -6; z: 10; cursorShape: Qt.SizeVerCursor
                        property real sy; property real oy; property real oh
                        onPressedChanged: { if (pressed) { sy = mouseY; oy = cropDialog.selY; oh = cropDialog.selH; } }
                        onPositionChanged: { var nh = oh + (mouseY - sy); selRect.applySel(cropDialog.selX, oy, cropDialog.selW, nh); }
                    }
                    // 左边缩放
                    MouseArea { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: 12; height: 40; anchors.leftMargin: -6; z: 10; cursorShape: Qt.SizeHorCursor
                        property real sx; property real ox; property real ow
                        onPressedChanged: { if (pressed) { sx = mouseX; ox = cropDialog.selX; ow = cropDialog.selW; } }
                        onPositionChanged: { var nw = ow - (mouseX - sx); selRect.applySel(ox + ow - nw, cropDialog.selY, nw, cropDialog.selH); }
                    }
                    // 右边缩放
                    MouseArea { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: 12; height: 40; anchors.rightMargin: -6; z: 10; cursorShape: Qt.SizeHorCursor
                        property real sx; property real ox; property real ow
                        onPressedChanged: { if (pressed) { sx = mouseX; ox = cropDialog.selX; ow = cropDialog.selW; } }
                        onPositionChanged: { var nw = ow + (mouseX - sx); selRect.applySel(ox, cropDialog.selY, nw, cropDialog.selH); }
                    }
                } // selRect
            } // cropContainer

            Column {
                width: parent.width; spacing: 8
                Label { text: tt("dragToMove"); color: cSub; anchors.horizontalCenter: parent.horizontalCenter }
                Row {
                    spacing: 8; anchors.horizontalCenter: parent.horizontalCenter
                    Button { text: tt("useFull"); visible: cropDialog.mode === "bg"; onClicked: { root.bgImagePath = dbManager.importCover(cropDialog.sourcePath); root.currentBgHistoryId = -1; dbManager.addBgImage(root.bgImagePath, root.bgOpacity, root.bgBlur); cropDialog.close(); }
                        background: Rectangle { color: cCard; radius: 4; border.color: cBorder; border.width: 1; implicitHeight: 32 } }
                    Button {
                        text: tt("replaceCover"); visible: cropDialog.mode === "cover" || cropDialog.mode === "coverDetail"
                        background: Rectangle { color: cCard; radius: 4; border.color: cBorder; border.width: 1; implicitHeight: 32 }
                        onClicked: {
                            var cp = dbManager.importCover(cropDialog.sourcePath);
                            if (cropDialog.mode === "cover") { editCoverPath.text = cp; }
                            else {
                                dbManager.updateGame(gameDetailDialog.detailGameId, gameDetailDialog.detailGameName, gameDetailDialog.detailGameTypes,
                                    gameDetailDialog.detailGameRating, gameDetailDialog.detailGameStatus, 0,
                                    gameDetailDialog.detailGameStartDate, gameDetailDialog.detailGameFinishDate, gameDetailDialog.detailGameNotes, cp);
                                gameDetailDialog.detailGameCover = cp;
                                gameListModel.refresh(searchField.text);
                            }
                            cropDialog.close();
                        }
                    }
                    BtnOk { text: tt("cropBtn"); onClicked: cropDialog.doCrop() }
                    BtnCancel { onClicked: cropDialog.close() }
                }
            }
        } // Column
        onVisibleChanged: {
            if (!visible) {
                // 封面裁剪完成后返回来源窗口
                if (mode === "cover" && editDialog.visible) editDialog.requestActivate()
                else if (mode === "coverDetail" && gameDetailDialog.visible) gameDetailDialog.requestActivate()
                else if (mode === "bg" && bgHistoryDialog.visible) { bgHistoryDialog.refresh(); bgHistoryDialog.requestActivate() }
                mode = "bg"   // 重置模式
            }
        }
    }
    FileDialog {
        id: bgImageDialog; title: tt("selectImage")
        nameFilters: ["图片文件 (*.jpg *.jpeg *.png *.bmp *.webp *.gif)", "视频文件 (*.mp4)"]
        onAccepted: {
            var p = urlToPath(currentFile);
            // GIF 动画跳过裁剪（裁剪会丢失帧），直接设为背景
            if (isVideoFile(p)) {
                // 视频复制副本到 data/bg_videos/，定位到副本（与图片裁剪后存 data/crops/ 一致）
                var vp = dbManager.importBgVideo(p);
                if (vp.length > 0) { root.bgImagePath = vp; root.currentBgHistoryId = -1; dbManager.addBgImage(vp, root.bgOpacity, root.bgBlur); }
            } else if (p.toLowerCase().endsWith(".gif")) {
                root.bgImagePath = p; root.currentBgHistoryId = -1; dbManager.addBgImage(p, root.bgOpacity, root.bgBlur);
            } else { cropDialog.openBg(p); }
        }
    }
    // ===== HSV 颜色选择器组件（SV 方块 + 色相条）=====
    // 用法：Loader { sourceComponent: hsvPickerComp; Binding on item ... }
    // 外部通过 item.selectedColor 读写当前颜色
    Component {
        id: hsvPickerComp
        Item {
            id: hsvRoot
            // 外部接口属性：双向绑定的当前颜色
            property color selectedColor: "#ff0000"
            // 内部 HSV 状态
            property real hue: 0.0
            property real sat: 1.0
            property real val: 1.0
            // 防循环标志：拖动时由内部驱动，忽略外部回写
            property bool internalChange: false

            // 外部颜色变化 → 更新内部 HSV（如点击预设色块、输入十六进制）
            onSelectedColorChanged: {
                if (internalChange) return
                var r = selectedColor.r, g = selectedColor.g, b = selectedColor.b
                var max = Math.max(r, Math.max(g, b))
                var min = Math.min(r, Math.min(g, b))
                var d = max - min
                var h = 0
                if (d > 0) {
                    if (max === r) h = ((g - b) / d) % 6
                    else if (max === g) h = (b - r) / d + 2
                    else h = (r - g) / d + 4
                    h = h / 6
                    if (h < 0) h += 1
                }
                hue = h
                sat = max > 0 ? d / max : 0
                val = max
            }

            // HSV → color 转换函数
            function hsvToColor(h, s, v) {
                var i = Math.floor(h * 6)
                var f = h * 6 - i
                var p = v * (1 - s)
                var q = v * (1 - f * s)
                var t = v * (1 - (1 - f) * s)
                var r, g, b
                switch (i % 6) {
                    case 0: r = v; g = t; b = p; break
                    case 1: r = q; g = v; b = p; break
                    case 2: r = p; g = v; b = t; break
                    case 3: r = p; g = q; b = v; break
                    case 4: r = t; g = p; b = v; break
                    case 5: r = v; g = p; b = q; break
                }
                return Qt.rgba(r, g, b, 1)
            }
            // 拖动时回写 selectedColor（设标志避免触发 onSelectedColorChanged 回环）
            function emitColor() {
                internalChange = true
                selectedColor = hsvToColor(hue, sat, val)
                internalChange = false
            }

            width: 300; height: 180

            // SV 方块（左到右饱和度 0→1，上到下明度 1→0）
            Canvas {
                id: svCanvas
                width: parent.width - 32; height: parent.height
                anchors.left: parent.left
                onPaint: {
                    var ctx = getContext("2d")
                    var pure = hsvRoot.hsvToColor(hsvRoot.hue, 1, 1)
                    ctx.fillStyle = pure
                    ctx.fillRect(0, 0, width, height)
                    var gradW = ctx.createLinearGradient(0, 0, width, 0)
                    gradW.addColorStop(0, "rgba(255,255,255,1)")
                    gradW.addColorStop(1, "rgba(255,255,255,0)")
                    ctx.fillStyle = gradW
                    ctx.fillRect(0, 0, width, height)
                    var gradB = ctx.createLinearGradient(0, 0, 0, height)
                    gradB.addColorStop(0, "rgba(0,0,0,0)")
                    gradB.addColorStop(1, "rgba(0,0,0,1)")
                    ctx.fillStyle = gradB
                    ctx.fillRect(0, 0, width, height)
                }
                Connections { target: hsvRoot; function onHueChanged() { svCanvas.requestPaint() } }

                MouseArea {
                    anchors.fill: parent
                    function updateSV(mx, my) {
                        hsvRoot.sat = Math.max(0, Math.min(1, mx / parent.width))
                        hsvRoot.val = Math.max(0, Math.min(1, 1 - my / parent.height))
                        hsvRoot.emitColor()
                    }
                    onPressed: function(mouse) { updateSV(mouse.x, mouse.y) }
                    onPositionChanged: function(mouse) { updateSV(mouse.x, mouse.y) }
                }
                Rectangle {
                    x: svCanvas.width * hsvRoot.sat - 6
                    y: svCanvas.height * (1 - hsvRoot.val) - 6
                    width: 12; height: 12; radius: 6
                    color: "transparent"
                    border.color: "#ffffff"; border.width: 2
                    Rectangle { anchors.fill: parent; radius: parent.radius; color: "transparent"; border.color: "#000000"; border.width: 1; anchors.margins: -1 }
                }
            }

            // 色相条（垂直彩虹）
            Canvas {
                id: hueCanvas
                width: 24; height: parent.height
                anchors.right: parent.right
                onPaint: {
                    var ctx = getContext("2d")
                    var grad = ctx.createLinearGradient(0, 0, 0, height)
                    for (var i = 0; i <= 6; i++)
                        grad.addColorStop(i / 6, hsvRoot.hsvToColor(i / 6, 1, 1))
                    ctx.fillStyle = grad
                    ctx.fillRect(0, 0, width, height)
                }
                MouseArea {
                    anchors.fill: parent
                    function updateH(my) {
                        hsvRoot.hue = Math.max(0, Math.min(1, my / parent.height))
                        hsvRoot.emitColor()
                    }
                    onPressed: function(mouse) { updateH(mouse.y) }
                    onPositionChanged: function(mouse) { updateH(mouse.y) }
                }
                Rectangle {
                    y: hueCanvas.height * hsvRoot.hue - 4
                    width: parent.width; height: 8
                    color: "transparent"
                    border.color: "#ffffff"; border.width: 2
                    Rectangle { anchors.fill: parent; color: "transparent"; border.color: "#000000"; border.width: 1; anchors.margins: -1 }
                }
            }
        }
    }
    // ===== 自定义颜色选择窗口（4 个实例共用 ColorPickerDialog 组件）=====
    ColorPickerDialog {
        id: customAccentDialog
        title: tt("customAccent")
        initialColor: root.customAccent
        presetColors: ["#ff4444", "#ff8844", "#ffc94d", "#5bd06d", "#27d2bf", "#3a9fff", "#9b5de5", "#ff7aa8", "#222222", "#888888", "#bbbbbb", "#ffffff"]
        onAccepted: root.customAccent = c
    }

    ColorPickerDialog {
        id: customBgColorDialog
        title: tt("customBg")
        initialColor: root.customBgColor
        presetColors: ["#ff4444", "#ff8844", "#ffc94d", "#5bd06d", "#27d2bf", "#3a9fff", "#9b5de5", "#ff7aa8", "#222222", "#888888", "#bbbbbb", "#ffffff"]
        onAccepted: root.customBgColor = c
    }

    ColorPickerDialog {
        id: customTextColorDialog
        title: tt("mainTextColor")
        initialColor: root.customTextColor
        previewText: tt("aaBbText")
        presetColors: ["#222222", "#444444", "#666666", "#1a3a5c", "#5c1a3a", "#3a5c1a", "#5c3a1a", "#e8e8ec", "#ffffff", "#ffd700", "#1a1a1a", "#888888"]
        onAccepted: { root.customTextColor = c; root.customTextColorSet = true }
    }

    ColorPickerDialog {
        id: customSubColorDialog
        title: tt("subTextColor")
        initialColor: root.customSubColor
        previewText: tt("aaBbDesc")
        previewBgColor: root.customBgColor
        previewFontSize: 14
        previewOutline: false
        presetColors: ["#666666", "#888888", "#9999aa", "#4a6a8a", "#8a4a6a", "#4a8a6a", "#8a6a4a", "#bbbbbb", "#cccccc", "#ff9966", "#aaaaaa", "#555555"]
        onAccepted: { root.customSubColor = c; root.customSubColorSet = true }
    }
}
