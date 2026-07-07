--[[--------------------------------------------------------------------
  SolaQoL - Korean Locale (koKR)
--------------------------------------------------------------------]]--

local locale = GetLocale()
if locale ~= "koKR" then return end

local L = SolaQoL_L

-- ===== Default Messages =====
L.MSG_HELLO_DEFAULT     = "안녕하세요"
L.MSG_GG_DEFAULT        = "수고하셨습니다"
L.MSG_FULL              = "파티원이 모두 모였습니다"
L.MSG_NEW_APPLICANT     = "새로운 파티 신청자!!"

-- ===== Tooltip / Item Level =====
L.ILVL_COLON            = "아이템 레벨:"
L.ILVL_PREFIX           = "아이템 레벨: "
L.ILVL_LOADING          = "정보 불러오는 중..."

-- ===== Garbage Detection =====
L.GARBAGE_UNKNOWN1      = "무엇인가"
L.GARBAGE_UNKNOWN2      = "알 수 없음"

-- ===== Chat Output =====
L.PARTY_JOIN_HEADER     = "[파티 합류]"
L.PARTY_ILVL_HEADER     = "[파티원 아이템 레벨]"
L.NOTICE                = "[알림]"
L.PARTY_RECRUIT         = "[파티 모집]"
L.APPLICANT_WAITING_FMT = " (현재 대기: %d명)"
L.PORTAL_ACTIVATED_FMT  = "%s 포탈 주문이 활성화되었습니다!"
L.NO_GROUP              = "현재 소속된 그룹이 없습니다."
L.GREETING_CHANGED_FMT  = "인사말 변경: %s"
L.GREETING_CHANGED_RAND_FMT = "인사말 변경: %s |cff888888(이 중 하나가 무작위로 선택되어 전송됩니다)|r"
L.GG_CHANGED_FMT        = "종료 메시지 변경: %s"
L.GG_CHANGED_RAND_FMT   = "종료 메시지 변경: %s |cff888888(이 중 하나가 무작위로 선택되어 전송됩니다)|r"
L.AUTO_GREET_FEEDBACK_FMT = "자동 인사 출력: %s초"
L.TOGGLE_MSG_FMT        = "%s 기능이 %s."
L.TOGGLE_ON_MSG         = "켜졌습니다"
L.TOGGLE_OFF_MSG        = "꺼졌습니다"

-- ===== Portal UI =====
L.PORTAL_LABEL          = "던전 포탈"
L.CANCEL                = "취소"
L.ANNOUNCE_DESTINATION  = "목적지 알림"
L.ANNOUNCE_MSG_FMT      = "[SolaQoL] 목적지 알림: %3$s"
L.OVERLAY_PORTAL_FMT    = "파티 합류: %s"
L.BTN_TEST_MODE         = "위치/크기 변경"
L.BTN_TEST_MODE_OFF     = "변경 완료"
L.TEST_MODE_LABEL       = "좌클릭: 이동 / 마우스휠: 크기 조절"

-- ===== Config UI - Categories =====
L.CAT_GREETINGS         = "인사 및 알림"
L.CAT_GREETINGS_SUB     = "인사말"
L.SOUND_TITLE_SETTINGS  = "사운드 설정"
L.CAT_CONVENIENCE       = "편의 기능"
L.CAT_COMBAT_PARTY      = "전투 및 파티플레이"
L.CAT_PLAYER_INFO       = "개인 설정"
L.CAT_TRADE_RESULT_ALERTS = "거래 결과 알림"
L.CAT_ILVL_SCAN         = "플레이어 정보"
L.CAT_TRADE             = "거래 알림 설정"
L.UI_SCALE              = "UI 크기 조절"
L.MINIMAP               = "미니맵"
L.MINIMAP_TOOLTIP       = "클릭하여 설정 창 열기\n드래그하여 위치 이동"

-- ===== Config UI - Options =====
L.WELCOME_MSG_FMT       = "|cff00ccff[SolaQoL]|r %s 활성화됨. 설정 명령어는 |cff00ccff/SQ|r 입니다. |cfffeca57Sola-아즈샤라 제작|r"
L.OPT_AUTO_GREET        = "파티 자동 인사 |cff888888(쉼표로 구분)|r"
L.OPT_AUTO_GREET_MSG    = "파티 자동 인사"
L.OPT_GREET_ONCE        = "파티원일 때는 최초 1회만 인사"
L.OPT_GG_COMPLETE       = "쐐기 던전 완료 인사 |cff888888(쉼표로 구분)|r"
L.OPT_GG_COMPLETE_MSG   = "쐐기 던전 완료 인사"
L.OPT_RAID_SOUND        = "[공격대] 플레이어 합류 알림 사운드"
L.OPT_AUTO_PORTAL       = "쐐기 파티 참가 시 던전 정보 표시"
L.OPT_SHOW_SPEC_ON_ENTER = "인스턴스 입장 시 현재 선택된 특성 명 표시"
L.OPT_SHOW_SPEC_ON_ENTER_DESC = "위치 이동: ALT + 마우스 왼쪽 버튼\n크기 조절: ALT + 마우스 휠 스크롤"
L.SPEC_DISPLAY_FORMAT     = "현재 특성: %s"
L.OPT_SHOW_ILVL         = "파티원 아이템 레벨과 전문화 자동 요약 (나에게만 표시)"
L.OPT_SHOW_ILVL_SHORT   = "파티원 아이템 레벨과 전문화 자동 요약"
L.OPT_TOOLTIP_ILVL      = "마우스오버 대상 툴팁에 아이템 레벨 및 쐐기 점수 표시"
L.MYTHIC_SCORE_PREFIX   = "쐐기 점수: "
L.OPT_LUST_BAR_ENABLE   = "블러드 지속시간 바 사용"
L.BTN_TEST_LUST_BAR     = "블러드 바 테스트"
L.LUST_BAR_WIDTH        = "가로"
L.LUST_BAR_HEIGHT       = "세로"
L.BTN_ADD               = "추가"
L.BTN_DELETE            = "삭제"
L.BTN_CLOSE             = "닫기"
L.BTN_CONFIRM_CLOSE     = "확인 및 닫기"
L.BTN_TEST_STOP         = "테스트 종료"

-- ===== Config UI - Buttons =====
L.SAVE                  = "저장"
L.PLAY                  = "▶ 재생"
L.OPEN_SETTINGS         = "설정하기"
L.OPEN_SOUND_SETTINGS   = "사용자 설정 알림음 경로 지정.."

-- ===== Sound Config Window =====
L.SOUND_TITLE           = "사운드 경로 설정"
L.SOUND_HINT            = "* 빈칸으로 저장 시 기본 알림음이 재생됩니다."
L.SOUND_NEW_LABEL       = "파티 합류 알림음 사용자 설정"
L.SOUND_NEW_SAVED       = "파티 합류 사운드 경로 저장됨"
L.SOUND_FULL_LABEL      = "풀 파티 알림음 사용자 설정"
L.SOUND_FULL_SAVED      = "풀 파티 완료 사운드 경로 저장됨"
L.SOUND_APP_LABEL       = "새로운 지원자 알림음 사용자 설정"
L.SOUND_APP_SAVED       = "새로운 지원자 사운드 경로 저장됨"
L.SOUND_GUIDE1          = "Interface 폴더 하위 경로에 변경하고 싶은 사운드 파일(mp3, ogg)을 넣으세요."
L.SOUND_GUIDE2          = "예시) Interface\\AddOns\\SolaQoL\\Your_Sound.mp3"
L.SOUND_WARNING         = "※ 사운드 파일을 새로 넣었다면, 게임 클라이언트를 완전히 종료 후 재실행해야 인식됩니다."
L.SOUND_ERROR_EMPTY     = "사운드 경로를 입력해 주세요."
L.SOUND_ERROR_INVALID   = "올바르지 않은 사운드 경로 형식입니다. 'Interface\\' 폴더로 시작해야 하며, .mp3, .ogg 또는 .wav 확장자여야 합니다."

-- ===== Toggle State =====
L.TOGGLE_ON             = "|cff88ff88켜짐|r"
L.TOGGLE_OFF            = "|cffff8888꺼짐|r"
L.SOUND_NEW_ON          = "파티 합류 알림음이 |cff66ff66켜졌습니다|r."
L.SOUND_NEW_OFF         = "파티 합류 알림음이 |cffff6666꺼졌습니다|r."
L.SOUND_FULL_ON         = "풀 파티 알림음이 |cff66ff66켜졌습니다|r."
L.SOUND_FULL_OFF        = "풀 파티 알림음이 |cffff6666꺼졌습니다|r."
L.SOUND_APP_ON          = "새로운 지원자 알림음이 |cff66ff66켜졌습니다|r."
L.SOUND_APP_OFF         = "새로운 지원자 알림음이 |cffff6666꺼졌습니다|r."

-- ===== Trade Report =====
L.CAT_TRADE             = "거래 알림 설정"
L.OPT_TRADE_ENABLE      = "거래결과 요약 알림 (나에게만 표시)"
L.TRADE_LOG_ENABLE      = "이전 거래 내역"
L.TRADE_LOG_CLEAR       = "내역 지우기"
L.TRADE_LOG_EMPTY       = "기록된 거래 내역이 없습니다."
L.TRADE_LOG_TAMPERED    = "[변조됨]"
L.OPT_TRADE_WHISPER     = "대상에게 귓속말로 알림"
L.OPT_TRADE_PARTY       = "파티/공격대로 알림"
L.TRADE_SUMMARY_BOTH    = "%s 받음 / %s 보냄"
L.TRADE_SUMMARY_GAVE    = "%s 보냄"
L.TRADE_SUMMARY_RECV    = "%s 받음"
L.TRADE_SUMMARY_EMPTY   = "서로 주고받은 것 없음"
L.TRADE_GOLD            = " 골드 "
L.TRADE_SILVER          = " 실버 "
L.TRADE_COPPER          = " 코퍼 "
L.TRADE_SUCCESS         = "[거래 완료]"
L.TRADE_CANCELLED       = "[거래 취소]"
L.TRADE_ERROR_HDR       = "[거래 오류]"
L.TRADE_REASON_ME       = "내가 취소함"
L.TRADE_REASON_TARGET   = "상대방이 취소함"
L.TRADE_REASON_UNKNOWN  = "알 수 없는 이유"
L.TRADE_ERROR           = "거래 오류"
L.TRADE_WITH_UNKNOWN    = "알 수 없는 대상"

-- ===== Keyword Alert =====
L.OPT_KEYWORD_ALERT       = "키워드 알림 사용"
L.OPT_KEYWORD_ALERT_SHORT = "키워드 알림"
L.OPT_KEYWORD_LIST         = "알림 키워드 (쉼표로 구분):"
L.OPT_KEYWORD_SOUND        = "알림 사운드:"
L.KEYWORD_SOUND_WHISPER     = "귓속말 알림"
L.KEYWORD_SOUND_READY_CHECK = "전투 준비"
L.KEYWORD_SOUND_RAID_WARNING = "공격대 경고"
L.KEYWORD_SOUND_LEVEL_UP    = "레벨업"
L.KEYWORD_SOUND_ALARM       = "알람 시계"
L.BTN_KEYWORD_TEST          = "\226\150\182 재생"
L.SOUND_OPT_CUSTOM          = "사용자 설정"
L.SOUND_OPT_DEFAULT         = "기본음 (DEFAULT)"
L.OPT_KEYWORD_AUTO_PLAYER       = "현재 접속 중인 캐릭터 명을 알림 키워드에 자동으로 추가"
L.OPT_KEYWORD_AUTO_PLAYER_SHORT = "현재 캐릭터 명 자동 추가"

-- ===== Auto-Release Spirit =====
L.OPT_AUTO_RELEASE          = "사망 시 영혼으로 자동 전환"
L.OPT_AUTO_RELEASE_SHORT    = "자동 영혼 전환"
L.OPT_AUTO_RELEASE_DESC     = "영혼석, 윤회, 전투 부활을 받았을 경우에는 동작하지 않습니다. (레이드 트라이용)"
L.OPT_DISABLE_AUTO_RELEASE_HUD = "영전 활성화 상태 표시기 비활성화"

-- ===== Dungeon Portals =====
L.DungeonPortals = {
    ["삼두정의 권좌"]     = 1254551,
    ["사론의 구덩이"]     = 1254555,
    ["하늘탑"]           = 159898,
    ["윈드러너 첨탑"]     = 1254400,
    ["마법학자의 정원"]   = 1254572,
    ["공결탑 제나스"]     = 1254563,
    ["마이사라 동굴"]     = 1254559,
    ["알게타르 대학"]     = 393273,
}

L.DungeonShortNames = {
    ["삼두정의 권좌"]     = "삼두정",
    ["사론의 구덩이"]     = "사론",
    ["하늘탑"]           = "하늘탑",
    ["윈드러너 첨탑"]     = "첨탑",
    ["마법학자의 정원"]   = "마정",
    ["공결탑 제나스"]     = "제나스",
    ["마이사라 동굴"]     = "마이사라",
    ["알게타르 대학"]     = "대학",
}

-- ===== Random Hearthstone =====
L.CAT_RANDOM_HEARTHSTONE  = "무작위 장난감 귀환석 시전"
L.OPT_RANDOM_HEARTHSTONE  = "무작위 귀환석"
L.BIND_NOT_SET            = "단축키 지정"
L.BTN_HEARTHSTONE_LIST    = "귀환석 추가/제거"
L.BTN_UNBIND              = "삭제"
L.HEARTHSTONE_POPUP_TITLE = "귀환석 목록"
L.MSG_UNBOUND             = "단축키 해제됨"
L.OPT_HEARTHSTONE_ON_CLEAR= "쐐기 파티 완료 시 무작위 귀환석 사용 팝업 표시"

L.OPT_BLOODLUST_ALERT_ENABLE = "블러드 텍스트 및 음성 알림 활성화"
L.OPT_BLOODLUST_START_ALERT = "블러드 시작 알림"
L.OPT_BLOODLUST_READY_ALERT = "블러드 준비 알림 (블러드 시전 가능 직업 한정)"
L.OPT_BLOODLUST_ALERT_PERSIST = "블러드 준비 메세지 상시 표시 (다음 시전 시까지 유지)"

L.OPT_LUST_MODE_BOTH = "텍스트 및 음성 알림"
L.OPT_LUST_MODE_TEXT = "텍스트 알림만"
L.OPT_LUST_MODE_AUDIO = "음성 알림만"
L.OPT_LUST_MODE_OFF = "사용 안 함"
L.BTN_TEST_BLOODLUST_ALERT = "알림 테스트"
L.MSG_BLOODLUST_READY = "블러드 준비"
L.MSG_BLOODLUST_START = "블러드 시작"
L.SOUND_BLOODLUST_READY = "LustRdy_kr.mp3"
L.SOUND_BLOODLUST_START = "LustOn_kr.mp3"
L.HUD_AUTO_RELEASE = "영전"

L.UPDATE_NOTE_LATEST = "- 블러드 사용 또는 준비되었을 때 텍스트 및 음성으로 알려주는 기능이 추가되었습니다."

L.CAT_CHANGELOG = "업데이트 내역"
L.UPDATE_POPUP_TEXT = "26-07-08 / 0.5.2\n\n |cffD4A745[ 신규 기능 안내 ]|r\n\n - 블러드가 시작되거나 재사용이 가능하게 되었을 때, 텍스트 및 음성으로 알려주는 기능이 추가되었습니다.\n\n |cffffff00/SQ|r 를 입력하고 설정 창에서 확인해 보세요."
L.CHANGELOG_TEXT = "26-07-08 / 0.5.2\n - 블러드 사용 또는 준비되었을 때 텍스트 및 음성으로 알려주는 기능이 추가되었습니다.\n\n26-07-07 / 0.5.1\n - 사소한 버그 수정\n\n26-07-06 / 0.5.0\n - 애드온의 이름이 'SolaQoL'로 변경되었습니다.\n\n26-07-01 / 0.4.4\n - 무작위 귀환석 장난감 기능이 추가되었습니다. 설정 창의 귀환석 탭에서 원하는 장난감을 추가/제외할 수 있습니다. 단축키 지정도 가능합니다.\n\n26-06-30 / 0.4.3\n - 던전 포탈 오버레이 텍스트의 위치/크기 조절이 저장되지 않던 문제 수정\n\n26-06-27 / 0.4.2\n - 목적지 알림 버튼이 클릭되지 않던 문제 수정\n\n26-06-26 / 0.4.1\n - 알림 키워드에 내 캐릭터 이름을 자동으로 추가하는 기능 추가\n\n26-06-26 / 0.4.0\n - 자동 영혼 해방 기능이 공격대에서 작동하지 않던 문제 수정\n\n26-06-25 / 0.3.9\n - UI 재설계, 메모리 릭 최적화 및 구조 개선, 마이너 버그 수정\n - 채팅 키워드 알림 기능 추가\n - 초고속 자동 영혼 해방 기능 추가 (쐐기/레이드 트라이용)\n - 영구적인 거래 내역 테이블 추가 (리로드나 재접속시에도 유지, 조작 감지 기능 탑재)\n - 알림음에 다양한 선택지 제공"

-- ===== Key Bindings =====
BINDING_HEADER_SOLAQOL = "SolaQoL"
BINDING_NAME_PG_RANDOM_HEARTHSTONE = "무작위 장난감 귀환석 시전"
