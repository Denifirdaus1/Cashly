# Cashly Fast Home Screen Widget Setup

## Overview
This Flutter app includes an Android home screen widget that displays today's total income and expense, along with a button to quickly add new transactions.

## Widget Features
- **Today's Summary**: Shows total income and expense for today
- **Currency Format**: Uses Indonesian Rupiah (Rp) format
- **Quick Add**: Button to launch the app directly to add transaction screen
- **Real-time Updates**: Updates automatically when new transactions are added

## Adding the Widget to Home Screen

### Android 8.0+ (Oreo and above)
1. Long press on an empty area of your home screen
2. Select "Widgets" or "Add Widgets"
3. Find "Cashly Fast" in the widget list
4. Drag the widget to your desired location on the home screen

### Android 7.0 and below
1. Long press on an empty area of your home screen
2. Select "Widgets"
3. Find "Cashly Fast" widget
4. Long press and drag to home screen

## Widget Display
The widget shows:
- **Title**: "Total Hari Ini:"
- **Income**: Today's total income (e.g., Rp120.000)
- **Expense**: Today's total expense (e.g., Rp50.000)
- **Button**: "Tambah Transaksi" - launches the app

## Technical Details

### Data Storage
- Uses SharedPreferences for storing daily totals
- Data resets automatically at midnight
- Stores income and expense as integers (rupiah)

### Update Frequency
- Widget updates every 30 minutes (1800000ms)
- Also updates immediately when new transactions are added via the app

### Dependencies
- `home_widget` package for Android home screen widget support
- `shared_preferences` for data storage
- `intl` package for currency formatting

## Development Notes

### File Structure
```
android/app/src/main/
├── kotlin/com/example/cash_inout_app/
│   └── HomeWidgetProvider.kt    # Android widget provider
├── res/layout/
│   └── widget_layout.xml       # Widget UI layout
├── res/drawable/
│   ├── widget_background.xml   # Widget background
│   ├── widget_button_background.xml # Button background
│   └── widget_preview.xml      # Widget preview image
└── res/xml/
    └── home_widget_info.xml    # Widget metadata
```

### Flutter Integration
- `lib/services/widget_service.dart` handles widget data updates
- `lib/config/widget_config.dart` contains widget configuration constants
- Widget data is updated via SharedPreferences when transactions are added

## Troubleshooting

### Widget Not Appearing
1. Ensure the app is installed (not just running in debug mode)
2. Check if widgets are supported on your Android version
3. Try restarting the device

### Data Not Updating
1. Ensure the app has been opened at least once after installation
2. Check if transactions are being added successfully in the app
3. Try removing and re-adding the widget

### Currency Format Issues
- The widget uses Indonesian Rupiah format (Rp)
- Format: Rp120.000 (no decimal places)
- Uses device locale for proper number formatting

## Testing
To test the widget:
1. Install the app on an Android device/emulator
2. Add the widget to home screen
3. Open the app and add some transactions
4. Check if widget updates with new totals
5. Verify the "Tambah Transaksi" button launches the app correctly