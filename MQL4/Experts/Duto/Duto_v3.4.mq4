/*

This EA is derived from the MT4 Robot Template and it is for demonstration and education purpose

ENTRY SIGNAL: Fast MA crosses Slow MA

EXIT SIGNAL: Fast MA Crosses Slow MA

STOP LOSS: Set to the parabolic sar (PSAR)

TRAILING STOP: Stop following the PSAR

*/

//-PROPERTIES-//
// Properties help the software look better when you load it in MT4
// Provide more information and details
// This is what you see in the About tab when you load an indicator or an Expert Advisor
#property link "https://www.earnforex.com/metatrader-expert-advisors/expert-advisor-template/"
#property version "1.00"
#property strict
#property copyright "EarnForex.com - 2020-2021"
#property description "This is a template for a generic Automated EA"
#property description " "
#property description "WARNING : You use this software at your own risk."
#property description "The creator of these plugins cannot be held responsible for any damage or loss."
#property description " "
#property description "Find More on EarnForex.com"
// You can add an icon for when the EA loads on chart but it's not necessary
// The commented line below is an example of icon, icon must be in the MQL4/Files folder and have a ico extension
// #property icon          "\\Files\\EF-Icon-64x64px.ico"

//-INCLUDES-//
// Include allows to import code from another file
// In the following instance the file has to be placed in the MQL4/Include Folder
#include <MQLTA ErrorHandling.mqh>


//-ENUMERATIVE VARIABLES-//
// Enumerative variables are useful to associate numerical values to easy to remember strings
// It is similar to constants but also helps if the variable is set from the input page of the EA
// The text after the // is what you see in the input paramenters when the EA loads
// It is good practice to place all the enumberative at the start
enum ENUM_HOUR
{
   h00 = 00, // 00:00
   h01 = 01, // 01:00
   h02 = 02, // 02:00
   h03 = 03, // 03:00
   h04 = 04, // 04:00
   h05 = 05, // 05:00
   h06 = 06, // 06:00
   h07 = 07, // 07:00
   h08 = 08, // 08:00
   h09 = 09, // 09:00
   h10 = 10, // 10:00
   h11 = 11, // 11:00
   h12 = 12, // 12:00
   h13 = 13, // 13:00
   h14 = 14, // 14:00
   h15 = 15, // 15:00
   h16 = 16, // 16:00
   h17 = 17, // 17:00
   h18 = 18, // 18:00
   h19 = 19, // 19:00
   h20 = 20, // 20:00
   h21 = 21, // 21:00
   h22 = 22, // 22:00
   h23 = 23, // 23:00
};

enum ENUM_SIGNAL_ENTRY{
   SIGNAL_ENTRY_NEUTRAL=0,    //SIGNAL ENTRY NEUTRAL
   SIGNAL_ENTRY_BUY=1,        //SIGNAL ENTRY BUY
   SIGNAL_ENTRY_SELL=-1,      //SIGNAL ENTRY SELL
};

enum ENUM_SIGNAL_EXIT{
   SIGNAL_EXIT_NEUTRAL=0,     //SIGNAL EXIT NEUTRAL
   SIGNAL_EXIT_BUY=1,         //SIGNAL EXIT BUY
   SIGNAL_EXIT_SELL=-1,        //SIGNAL EXIT SELL
   SIGNAL_EXIT_ALL=2,         //SIGNAL EXIT ALL
};

ENUM_SIGNAL_ENTRY SignalEntry = SIGNAL_ENTRY_NEUTRAL; // Entry signal variable
ENUM_SIGNAL_EXIT SignalExit=SIGNAL_EXIT_NEUTRAL;         //Exit signal variable

enum ENUM_TRADING_ALLOW_DIRECTION
{
   TRADING_ALLOW_BOTH = 0,  // ALLOW BOTH BUY AND SELL
   TRADING_ALLOW_BUY = 1,   // ALLOW BUY ONLY
   TRADING_ALLOW_SELL = -1, // ALLOW SELL ONLY
};

enum ENUM_RISK_BASE
{
   RISK_BASE_EQUITY = 1,     // EQUITY
   RISK_BASE_BALANCE = 2,    // BALANCE
   RISK_BASE_FREEMARGIN = 3, // FREE MARGIN
};

enum ENUM_RISK_DEFAULT_SIZE
{
   RISK_DEFAULT_FIXED = 1, // FIXED SIZE
   RISK_DEFAULT_AUTO = 2,  // AUTOMATIC SIZE BASED ON RISK
};

enum ENUM_MODE_SL
{
   SL_FIXED = 0, // FIXED STOP LOSS
   SL_AUTO = 1,  // AUTOMATIC STOP LOSS
};

enum ENUM_MODE_TP
{
   TP_FIXED = 0, // FIXED TAKE PROFIT
   TP_AUTO = 1,  // AUTOMATIC TAKE PROFIT
};

enum ENUM_MODE_SL_BY
{
   SL_BY_POINTS = 0, // STOP LOSS PASSED IN POINTS
   SL_BY_PRICE = 1,  // STOP LOSS PASSED BY PRICE
};

//********************************************************************************************************
//DUTO EA SPECIFIC INPUTS
//********************************************************************************************************

//selected time frame
enum ENUM_UPPER_TIME_FRAME
{
   TIME_FRAME_H1 = 0, // H1
   TIME_FRAME_M15 = 10, // M15
   TIME_FRAME_M5 = 20, // M5
};

//selected trade exit plot
enum ENUM_EXIT_PLOT
{
   PLOT_1 = 6, // MACD
   PLOT_2 = 7, // Plot 2
};

/* //selected allow opposite dark on plot 2
enum ENUM_ALLOW_OPP_PL2
{
   ALLOW_OPP_PL2_YES = 1, // YES
   ALLOW_OPP_PL2_NO = 0, // NO
}; */

//selected allow opposite dark on plot 2
enum ENUM_ALLOW_OPP_SUDDEN_DARK
{
   ALLOW_OPP_SDDN_DARK_YES = 1, // YES
   ALLOW_OPP_SDDN_DARK_NO = 0, // NO
};

//upper left information section
input string Comment_5 = "=========="; // Duto Specific Settings
input ENUM_UPPER_TIME_FRAME UpperTimeFrame = TIME_FRAME_M5; // Upper time frame
input double BarColorCountThreshold = 3.5;  // BarColorCount Threshold
input double BarCountThreshold = 20;  // Bar Count Threshold
input int LookBackCount = 20;
input ENUM_EXIT_PLOT TradeExitPlot = 6; // Trade Exit Plot
//input ENUM_ALLOW_OPP_PL2 AllowOppDkPlot2 = 1; // Allow Entry if Plot 2 is Opp Dark
input ENUM_ALLOW_OPP_SUDDEN_DARK SuddenDarkEnabled = 1; // Sudden Dark Opp Trade

//********************************************************************************************************
//DUTO EA SPECIFIC VARIABLES
//********************************************************************************************************

//only allows an evaluation to be made if LogIndicatorData has been executed at least once
bool StartupFlag;
//string that will be written to the chart window
string SettingsComments;
//string that will be written to the chart window
string CandleComments;
//string that will be written to the chart window
string PipComments;

//STRATEGY AND TRADE VARIABLES
double EntryData[2][11];
string CurrentStrategy;
bool SellStrategyActive, BuyStrategyActive, NeutralStrategyActive;

bool BuyDkGrBrGrStrategyActive, SellBrGrDkGrStrategyActive;
bool SellDkGrBrRdStrategyActive, BuyBrRdDkRdStrategyActive;
bool SellDkRdBrRdStrategyActive, BuyDkRdBrGrStrategyActive;

bool SellTradeActive, BuyTradeActive, TradeActive;
bool SellTradePending, BuyTradePending, TradePending;

bool BuySafetyTrade2Strategy, SellSafetyTrade2Strategy, NeutralSafetyTrade2Strategy;

//HISTORY ARRAYS
//chart indicator history arrays
double FastMAHistoryBuffer[], SlowMAHistoryBuffer[], FiveFiftyMAHistoryBuffer[], DeltaCollapsedPosHistoryBuffer[], DeltaCollapsedNegHistoryBuffer[];
//MACD indicator history arrays
double MacdHistoryBuffer[],  MacdPlot2HistoryBuffer[], MacdPlot3HistoryBuffer[], MacdPlot4HistoryBuffer[];
//sniper indicator history array
int SniperHistoryBuffer[];
//a two dimensional array that stored indicator data from all time frames
//each time frame has 10 measurements
double CombinedHistory[1][52];

//LogIndicatorData() variables
string indicatorName = "_Custom\\Duto\\macd_color_indicator_plot1_v0.10";
string duto_chart_indicators = "_Custom\\Duto\\duto_chart_indicators_v0.6";
string duto_chart_moving_averages = "_Custom\\Duto\\duto_mas";
string duto_chart_deltas = "_Custom\\Duto\\delta_v0.1";
string duto_sniper = "_Custom\\Duto\\Sniper_v1";
string strWriteLine, strWriteLine2 = "";
int fileHandleIndicatorData;
int periodArray[] = {60, 15, 5};

//SNIPER VARIABLES
double LastHighest, LastLowest;
bool SniperCockedHigh, SniperCockedLow, SniperCockedNeutral;

//OPPORTUNITY TRADE SUDDEN DARK VARIABLES
string OpportunityStrategy;
bool SellSuddenDarkStrategy, BuySuddenDarkStrategy, NeutralSuddenDarkStrategy;
bool SuddenDarkSellActive, SuddenDarkBuyActive;


//********************************************************************************************************
//-INPUT PARAMETERS-//
// The input parameters are the ones that can be set by the user when launching the EA
// If you place a comment following the input variable this will be shown as description of the field
//********************************************************************************************************

// General input parameters
input string Comment_0 = "==========";                            // Risk Management Settings
input ENUM_RISK_DEFAULT_SIZE RiskDefaultSize = RISK_DEFAULT_AUTO; // Position Size Mode
input double DefaultLotSize = 1;                                  // Position Size (if fixed or if no stop loss defined)
input ENUM_RISK_BASE RiskBase = RISK_BASE_BALANCE;                // Risk Base
input int MaxRiskPerTrade = 2;                                    // Percentage To Risk Each Trade
input double MinLotSize = 0.01;                                   // Minimum Position Size Allowed
input double MaxLotSize = 100;                                    // Maximum Position Size Allowed
input double PSARStopStep = 0.04;                                 // Stop Loss PSAR Step
input double PSARStopMax = 0.4;                                   // Stop Loss PSAR Max

input string Comment_1 = "==========";                            // Trading Hours Settings
input bool UseTradingHours = false;                               // Limit Trading Hours
input ENUM_HOUR TradingHourStart = h07;                           // Trading Start Hour (Broker Server Hour)
input ENUM_HOUR TradingHourEnd = h19;                             // Trading End Hour (Broker Server Hour)

input string Comment_2 = "==========";                            // Stop Loss And Take Profit Settings
input ENUM_MODE_SL StopLossMode = SL_FIXED;                       // Stop Loss Mode
input int DefaultStopLoss = 0;                                    // Default Stop Loss In Points (0=No Stop Loss)
input int MinStopLoss = 0;                                        // Minimum Allowed Stop Loss In Points
input int MaxStopLoss = 5000;                                     // Maximum Allowed Stop Loss In Points
input ENUM_MODE_TP TakeProfitMode = TP_FIXED;                     // Take Profit Mode
input int DefaultTakeProfit = 0;                                  // Default Take Profit In Points (0=No Take Profit)
input int MinTakeProfit = 0;                                      // Minimum Allowed Take Profit In Points
input int MaxTakeProfit = 5000;                                   // Maximum Allowed Take Profit In Points

input string Comment_3 = "=========="; // Trailing Stop Settings
input bool UseTrailingStop = false;    // Use Trailing Stop

input string Comment_4 = "=========="; // Additional Settings
input int MagicNumber = 0;             // Magic Number For The Orders Opened By This EA
input string OrderNote = "";           // Comment For The Orders Opened By This EA
input int Slippage = 5;                // Slippage in points
input int MaxSpread = 100;             // Maximum Allowed Spread To Trade In Points

//********************************************************************************************************
//-GLOBAL VARIABLES-//
// The viables included in this section are global, hence they can be used in any part of the code
// It is useful to add a comment to remember what is the variable for
//********************************************************************************************************

bool IsPreChecksOk = false;      // Indicates if the pre checks are satisfied
bool IsNewCandle = false;        // Indicates if this is a new candle formed
bool IsSpreadOK = false;         // Indicates if the spread is low enough to trade
bool IsOperatingHours = false;   // Indicates if it is possible to trade at the current time (server time)
bool IsTradedThisBar = false;    // Indicates if an order was already executed in the current candle

double TickValue = 0;            // Value of a tick in account currency at 1 lot
double LotSize = 0;              // Lot size for the position

int OrderOpRetry = 10;           // Number of attempts to retry the order submission
int TotalOpenOrders = 0;         // Number of total open orders
int TotalOpenBuy = 0;            // Number of total open buy orders
int TotalOpenSell = 0;           // Number of total open sell orders
int StopLossBy = SL_BY_POINTS;   // How the stop loss is passed for the lot size calculation

//********************************************************************************************************
//-NATIVE MT4 EXPERT ADVISOR RUNNING FUNCTIONS-//
//********************************************************************************************************

// OnInit is executed once, when the EA is loaded
// OnInit is also executed if the time frame or symbol for the chart is changed
int OnInit()
{
   // It is useful to set a function to check the integrity of the initial parameters and call it as first thing
   CheckPreChecks();
   // If the initial pre checks have something wrong, stop the program
   if (!IsPreChecksOk)
   {
      OnDeinit(INIT_FAILED);
      return (INIT_FAILED);
   }
   // Function to initialize the values of the global variables
   InitializeVariables();
   /* // Function to initialize the logging of history
   InitializeLogging(); */

   // Function to initialize the 
   InitializeEASettingsComments();

   // If everything is ok the function returns successfully and the control is passed to a timer or the OnTike function
   return (INIT_SUCCEEDED);
}

// The OnDeinit function is called just before terminating the program
void OnDeinit(const int reason)
{
   // You can include in this function something you want done when the EA closes
   // For example clean the chart form graphical objects, write a report to a file or some kind of alert

   //FileClose(fileHandleIndicatorData); 
}

// The OnTick function is triggered every time MT4 receives a price change for the symbol in the chart
void OnTick()
{
   // Re-initialize the values of the global variables at every run
   InitializeVariables();

   InitializeEAPipComments();

   /* // Re-initialize the EA running comments at every tick
   InitializeEACandleComments() */

   // ScanOrders scans all the open orders and collect statistics, if an error occurs it skips to the next price change
   if (!ScanOrders())
      return;
   // CheckNewBar checks if the price change happened at the start of a new bar
   CheckNewBar();
   // CheckOperationHours checks if the current time is in the operating hours
   CheckOperationHours();
   // CheckSpread checks if the spread is above the maximum spread allowed
   CheckSpread();
   // CheckTradedThisBar checks if there was already a trade executed in the current candle
   CheckTradedThisBar();
   // EvaluateExit contains the code to decide if there is an exit signal
   EvaluateExit();
   // ExecuteExit executes the exit in case there is an exit signal
   ExecuteExit();
   // Scan orders again in case some where closed, if an error occurs it skips to the next price change
   if (!ScanOrders())
      return;
   // Execute Trailing Stop
   ExecuteTrailingStop();
   // EvaluateEntry contains the code to decide if there is an entry signal
   EvaluateEntry();
   // ExecuteEntry executes the entry in case there is an entry signal
   ExecuteEntry();
}

//-CUSTOM EA FUNCTIONS-//

// Perform integrity checks when the EA is loaded
void CheckPreChecks()
{
   IsPreChecksOk = true;
   if (!IsTradeAllowed())
   {
      IsPreChecksOk = false;
      Print("Live Trading is not enabled, please enable it in MT4 and chart settings");
      return;
   }
   if (DefaultStopLoss < MinStopLoss || DefaultStopLoss > MaxStopLoss)
   {
      IsPreChecksOk = false;
      Print("Default Stop Loss must be between Minimum and Maximum Stop Loss Allowed");
      return;
   }
   if (DefaultTakeProfit < MinTakeProfit || DefaultTakeProfit > MaxTakeProfit)
   {
      IsPreChecksOk = false;
      Print("Default Take Profit must be between Minimum and Maximum Take Profit Allowed");
      return;
   }
   if (DefaultLotSize < MinLotSize || DefaultLotSize > MaxLotSize)
   {
      IsPreChecksOk = false;
      Print("Default Lot Size must be between Minimum and Maximum Lot Size Allowed");
      return;
   }
   if (Slippage < 0)
   {
      IsPreChecksOk = false;
      Print("Slippage must be a positive value");
      return;
   }
   if (MaxSpread < 0)
   {
      IsPreChecksOk = false;
      Print("Maximum Spread must be a positive value");
      return;
   }
   if (MaxRiskPerTrade < 0 || MaxRiskPerTrade > 100)
   {
      IsPreChecksOk = false;
      Print("Maximum Risk Per Trade must be a percentage between 0 and 100");
      return;
   }
}

// Initialize variables
void InitializeVariables()
{
   IsNewCandle = false;
   IsTradedThisBar = false;
   IsOperatingHours = false;
   IsSpreadOK = false;

   LotSize = DefaultLotSize;
   TickValue = 0;

   TotalOpenBuy = 0;
   TotalOpenSell = 0;
   TotalOpenOrders = 0;

   SignalEntry = SIGNAL_ENTRY_NEUTRAL;
   SignalExit = SIGNAL_EXIT_NEUTRAL;
}

// Evaluate if there is an entry signal, called from the OnTickEvent
void EvaluateEntry()
{
   SignalEntry = SIGNAL_ENTRY_NEUTRAL;

   /* if (!IsSpreadOK)
      return; // If the spread is too high don't give an entry signal

   if (IsTradedThisBar)
      return; // If you don't want to execute multiple trades in the same bar

   if (TotalOpenOrders > 0)
      return; // If there are already open orders and you don't want to open more */

   // whether a new candle has been started is based on the chart that is shown
   if (IsNewCandle)
   {
      //Print("new candle in EvaluateEntry at: " + iTime(Symbol(), 1, 0));

      // Re-initialize the EA candle comments at every new candle
      InitializeEACandleComments();

      //log data and build the CombinedHistory array
      LogIndicatorData();
      //evaluate for a strategy
      //DutoWind_SelectedStrategy();

      //evaluate the sniper
      //EvaluateSniper();

      /* //evaluate the sudden dark opportunity trade
      if (SuddenDarkEnabled == 1 && UseTradingHours && IsOperatingHours)
      {
         EvaluateSuddenDark();
      } */

     EvaluateSuddenDark();

      /* LastHighest = GetLastHighestLowest("HIGHEST", 5, MODE_HIGH, LookBackCount, 1);
      LastLowest =GetLastHighestLowest("LOWEST", 5, MODE_LOW, LookBackCount, 1);

      CandleComments = CandleComments + 
      "Last Highest: " + LastHighest + "--Last Lowest: " + LastLowest + "\n"; */

      StartupFlag = true;

      //Comment(StringFormat("Show prices\nAsk = %G\nBid = %G = %d",Ask,Bid)); 
   }

   //this logic only allows an evaluation to be made if LogIndicatorData has been executed at least once
   if (StartupFlag ==  true && IsSpreadOK && !IsTradedThisBar && (!TotalOpenOrders > 0))
   { 
      // evaluate for a signal entry
      SignalEntry = ReturnSignalEntryToEvaluateEntry();
   }

   Comment(SettingsComments + CandleComments + PipComments); 
}

// Execute entry if there is an entry signal
void ExecuteEntry()
{
   // If there is no entry signal no point to continue
   if (SignalEntry == SIGNAL_ENTRY_NEUTRAL)
   //if (TradePending != true)
      return;

   int Operation;
   double OpenPrice = 0;
   double StopLossPrice = 0;
   double TakeProfitPrice = 0;
   // If there is a Buy entry signal
   if (SignalEntry == SIGNAL_ENTRY_BUY)
   {
      RefreshRates();     // Get latest rates
      Operation = OP_BUY; // Set the operation to BUY
      OpenPrice = Ask;    // Set the open price to Ask price
      // If the Stop Loss is fixed and the default stop loss is set
      if (StopLossMode == SL_FIXED && DefaultStopLoss > 0)
      {
         StopLossPrice = OpenPrice - DefaultStopLoss * Point;
      }
      // If the Stop Loss is automatic
      if (StopLossMode == SL_AUTO)
      {
         // Set the Stop Loss to the custom stop loss price
         StopLossPrice = StopLossPriceCalculate();
      }
      // If the Take Profix price is fixed and defined
      if (TakeProfitMode == TP_FIXED && DefaultTakeProfit > 0)
      {
         TakeProfitPrice = OpenPrice + DefaultTakeProfit * Point;
      }
      // If the Take Profit is automatic
      if (TakeProfitMode == TP_AUTO)
      {
         // Set the Take Profit to the custom take profit price
         TakeProfitPrice = TakeProfitCalculate();
      }
      // Normalize the digits for the float numbers
      OpenPrice = NormalizeDouble(OpenPrice, Digits);
      StopLossPrice = NormalizeDouble(StopLossPrice, Digits);
      TakeProfitPrice = NormalizeDouble(TakeProfitPrice, Digits);
      // Submit the order
      SendOrder(Operation, Symbol(), OpenPrice, StopLossPrice, TakeProfitPrice);
   }
   
   if (SignalEntry == SIGNAL_ENTRY_SELL)
   //if (SellTradePending == true && Bid >= CombinedHistory[0][32])
   {
      RefreshRates();      // Get latest rates

      Operation = OP_SELL; // Set the operation to SELL
      //Operation = OP_SELLSTOP; // Set the operation to SELL

      OpenPrice = Bid;     // Set the open price to Ask price
      // If the Stop Loss is fixed and the default stop loss is set
      if (StopLossMode == SL_FIXED && DefaultStopLoss > 0)
      {
         StopLossPrice = OpenPrice + DefaultStopLoss * Point;
      }
      // If the Stop Loss is automatic
      if (StopLossMode == SL_AUTO)
      {
         // Set the Stop Loss to the custom stop loss price
         StopLossPrice = StopLossPriceCalculate();
      }
      // If the Take Profix price is fixed and defined
      if (TakeProfitMode == TP_FIXED && DefaultTakeProfit > 0)
      {
         TakeProfitPrice = OpenPrice - DefaultTakeProfit * Point;
      }
      // If the Take Profit is automatic
      if (TakeProfitMode == TP_AUTO)
      {
         // Set the Take Profit to the custom take profit price
         TakeProfitPrice = TakeProfitCalculate();
      }
      // Normalize the digits for the float numbers
      OpenPrice = NormalizeDouble(OpenPrice, Digits);
      StopLossPrice = NormalizeDouble(StopLossPrice, Digits);
      TakeProfitPrice = NormalizeDouble(TakeProfitPrice, Digits);

      Print("Bid: " + Bid + ", CombinedHistory[1][32]: " + CombinedHistory[1][32]);
      // Submit the order
      SendOrder(Operation, Symbol(), OpenPrice, StopLossPrice, TakeProfitPrice);

      SellTradeActive = true;
      TradePending = false;
      SellTradePending = false;
   }
}

// Evaluate if there is an exit signal, called from the OnTickEvent
void EvaluateExit()
{
   SignalExit = SIGNAL_EXIT_NEUTRAL;

   // whether a new candle has been started is based on the chart that is shown
   if (IsNewCandle)
   {
      // Print("new candle in EvaluateEntry at: " + iTime(Symbol(), 1, 0));
      // log data and build the CombinedHistory array
      LogIndicatorData();
      StartupFlag = true;
   }

   //this logic only allows an evaluation to be made if LogIndicatorData has been executed at least once
   if (StartupFlag == true)
   {
      // evaluate for a signal entry
      SignalExit = ReturnSignalExitToEvaluateExit();
   }
}

// Execute exit if there is an exit signal
void ExecuteExit()
{
   // If there is no Exit Signal no point to continue the routine
   if (SignalExit == SIGNAL_EXIT_NEUTRAL)
      return;
   // If there is an exit signal for all orders
   if (SignalExit == SIGNAL_EXIT_ALL)
   {
      // Close all orders
      CloseAll(OP_ALL);
   }
   // If there is an exit signal for BUY order
   if (SignalExit == SIGNAL_EXIT_BUY)
   {
      // Close all BUY orders
      CloseAll(OP_BUY);
   }
   // If there is an exit signal for SELL orders
   if (SignalExit == SIGNAL_EXIT_SELL)
   {
      // Close all SELL orders
      CloseAll(OP_SELL);
   }
}

// Execute Trailing Stop to limit losses and lock in profits
void ExecuteTrailingStop()
{
   // If the option is off then exit
   if (!UseTrailingStop)
      return;
   // If there are no open orders no point to continue the code
   if (TotalOpenOrders == 0)
      return;
   // if(!IsNewCandle) return;      //If you only want to do the stop trailing once at the beginning of a new candle
   // Scan all the orders to see if some needs a stop loss update
   for (int i = 0; i < OrdersTotal(); i++)
   {
      // If there is a problem reading the order print the error, exit the function and return false
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
      {
         int Error = GetLastError();
         string ErrorText = GetLastErrorText(Error);
         Print("ERROR - Unable to select the order - ", Error, " - ", ErrorText);
         return;
      }
      // If the order is not for the instrument on chart we can ignore it
      if (OrderSymbol() != Symbol())
         continue;
      // If the order has Magic Number different from the Magic Number of the EA then we can ignore it
      if (OrderMagicNumber() != MagicNumber)
         continue;
      // Define current values
      RefreshRates();
      double SLPrice = NormalizeDouble(OrderStopLoss(), Digits);       // Current Stop Loss price for the order
      double TPPrice = NormalizeDouble(OrderTakeProfit(), Digits);     // Current Take Profit price for the order
      double Spread = MarketInfo(Symbol(), MODE_SPREAD) * Point;       // Current Spread for the instrument
      double StopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point; // Minimum distance between current price and stop loss

      // If it is a buy order then trail stop for buy orders
      if (OrderType() == OP_BUY)
      {
         // Include code to trail the stop for buy orders
         double NewSLPrice = 0;

         // This is where you should include the code to assign a new value to the STOP LOSS
         double PSARCurr = iSAR(Symbol(), PERIOD_CURRENT, PSARStopStep, PSARStopMax, 0);
         NewSLPrice = PSARCurr;

         double NewTPPrice = TPPrice;
         // Normalize the price before the submission
         NewSLPrice = NormalizeDouble(NewSLPrice, Digits);
         // If there is no new stop loss set then skip to next order
         if (NewSLPrice == 0)
            continue;
         // If the new stop loss price is lower than the previous then skip to next order, we only move the stop closer to the price and not further away
         if (NewSLPrice <= SLPrice)
            continue;
         // If the distance between the current price and the new stop loss is not enough then skip to next order
         // This allows to avoid error 130 when trying to update the order
         if (Bid - NewSLPrice < StopLevel)
            continue;
         // Submit the update
         ModifyOrder(OrderTicket(), OrderOpenPrice(), NewSLPrice, NewTPPrice);
      }
      // If it is a sell order then trail stop for sell orders
      if (OrderType() == OP_SELL)
      {
         // Include code to trail the stop for sell orders
         double NewSLPrice = 0;

         // This is where you should include the code to assign a new value to the STOP LOSS
         double PSARCurr = iSAR(Symbol(), PERIOD_CURRENT, PSARStopStep, PSARStopMax, 0);
         NewSLPrice = PSARCurr;

         double NewTPPrice = TPPrice;
         // Normalize the price before the submission
         NewSLPrice = NormalizeDouble(NewSLPrice, Digits);
         // If there is no new stop loss set then skip to next order
         if (NewSLPrice == 0)
            continue;
         // If the new stop loss price is higher than the previous then skip to next order, we only move the stop closer to the price and not further away
         if (NewSLPrice >= SLPrice)
            continue;
         // If the distance between the current price and the new stop loss is not enough then skip to next order
         // This allows to avoid error 130 when trying to update the order
         if (NewSLPrice - Ask < StopLevel)
            continue;
         // Submit the update
         ModifyOrder(OrderTicket(), OrderOpenPrice(), NewSLPrice, NewTPPrice);
      }
   }
   return;
}

// Check and return if the spread is not too high
void CheckSpread()
{
   // Get the current spread in points, the (int) transforms the double coming from MarketInfo into an integer to avoid a warning when compiling
   int SpreadCurr = (int)MarketInfo(Symbol(), MODE_SPREAD);
   if (SpreadCurr <= MaxSpread)
   {

      IsSpreadOK = true;
   }
   else
   {
      IsSpreadOK = false;
   }

   PipComments = PipComments + "IsSpreadOK: " + IsSpreadOK + "--SpreadCurr: " + SpreadCurr + 
   "--MaxSpread: " + MaxSpread + "\n";

   //Print("SpreadCurr: " + SpreadCurr + "MaxSpread: " + MaxSpread);
   //Print("IsSpreadOK: " + IsSpreadOK);
}

// Check and return if it is operation hours or not
void CheckOperationHours()
{
   // If we are not using operating hours then IsOperatingHours is true and I skip the other checks
   if (!UseTradingHours)
   {
      IsOperatingHours = true;
      return;
   }
   // Check if the current hour is between the allowed hours of operations, if so IsOperatingHours is set true
   if (TradingHourStart == TradingHourEnd && Hour() == TradingHourStart)
      IsOperatingHours = true;
   if (TradingHourStart < TradingHourEnd && Hour() >= TradingHourStart && Hour() <= TradingHourEnd)
      IsOperatingHours = true;
   if (TradingHourStart > TradingHourEnd && ((Hour() >= TradingHourStart && Hour() <= 23) || (Hour() <= TradingHourEnd && Hour() >= 0)))
      IsOperatingHours = true;
}

///*
// Check if it is a new bar
datetime NewBarTime = TimeCurrent();
void CheckNewBar()
{
   /* Print("NewBarTime:" + NewBarTime);
   Print("Time[0]:" + Time[0]); */

   // NewBarTime contains the open time of the last bar known
   // if that open time is the same as the current bar then we are still in the current bar, otherwise we are in a new bar
   if (NewBarTime == Time[0])
      IsNewCandle = false;
   else
   {
      NewBarTime = Time[0];
      IsNewCandle = true;
   }
}
///*

// Check if there was already an order open this bar
datetime LastBarTraded;
void CheckTradedThisBar()
{
   // LastBarTraded contains the open time the last trade
   // if that open time is in the same bar as the current then IsTradedThisBar is true
   if (iBarShift(Symbol(), PERIOD_CURRENT, LastBarTraded) == 0)
      IsTradedThisBar = true;
   else
      IsTradedThisBar = false;
}

// Lot Size Calculator
void LotSizeCalculate(double SL = 0)
{
   // If the position size is dynamic
   if (RiskDefaultSize == RISK_DEFAULT_AUTO)
   {
      // If the stop loss is not zero then calculate the lot size
      if (SL != 0)
      {
         double RiskBaseAmount = 0;
         // TickValue is the value of the individual price increment for 1 lot of the instrument, expressed in the account currenty
         TickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
         // Define the base for the risk calculation depending on the parameter chosen
         if (RiskBase == RISK_BASE_BALANCE)
            RiskBaseAmount = AccountBalance();
         if (RiskBase == RISK_BASE_EQUITY)
            RiskBaseAmount = AccountEquity();
         if (RiskBase == RISK_BASE_FREEMARGIN)
            RiskBaseAmount = AccountFreeMargin();
         // Calculate the Position Size
         LotSize = (RiskBaseAmount * MaxRiskPerTrade / 100) / (SL * TickValue);
      }
      // If the stop loss is zero then the lot size is the default one
      if (SL == 0)
      {
         LotSize = DefaultLotSize;
      }
   }
   // Normalize the Lot Size to satisfy the allowed lot increment and minimum and maximum position size
   LotSize = MathFloor(LotSize / MarketInfo(Symbol(), MODE_LOTSTEP)) * MarketInfo(Symbol(), MODE_LOTSTEP);
   // Limit the lot size in case it is greater than the maximum allowed by the user
   if (LotSize > MaxLotSize)
      LotSize = MaxLotSize;
   // Limit the lot size in case it is greater than the maximum allowed by the broker
   if (LotSize > MarketInfo(Symbol(), MODE_MAXLOT))
      LotSize = MarketInfo(Symbol(), MODE_MAXLOT);
   // If the lot size is too small then set it to 0 and don't trade
   if (LotSize < MinLotSize || LotSize < MarketInfo(Symbol(), MODE_MINLOT))
      LotSize = 0;
}

// Stop Loss Price Calculation if dynamic
double StopLossPriceCalculate()
{
   double StopLossPrice = 0;
   // Include a value for the stop loss, ideally coming from an indicator
   double PSARCurr = iSAR(Symbol(), PERIOD_CURRENT, PSARStopStep, PSARStopMax, 0);
   StopLossPrice = PSARCurr;

   return StopLossPrice;
}

// Take Profit Price Calculation if dynamic
double TakeProfitCalculate()
{
   double TakeProfitPrice = 0;
   // Include a value for the take profit, ideally coming from an indicator
   return TakeProfitPrice;
}

// Send Order Function adjusted to handle errors and retry multiple times
void SendOrder(int Command, string Instrument, double OpenPrice, double SLPrice, double TPPrice, datetime Expiration = 0)
{
   // Retry a number of times in case the submission fails
   for (int i = 1; i <= OrderOpRetry; i++)
   {
      // Set the color for the open arrow for the order
      color OpenColor = clrBlueViolet;
      if (Command == OP_BUY)
      {
         OpenColor = clrChartreuse;
      }
      if (Command == OP_SELL)
      {
         OpenColor = clrDarkTurquoise;
      }
      // Calculate the position size, if the lot size is zero then exit the function
      double SLPoints = 0;
      // If the Stop Loss price is set then find the points of distance between open price and stop loss price, and round it
      if (SLPrice > 0)
         MathCeil(MathAbs(OpenPrice - SLPrice) / Point);
      // Call the function to calculate the position size
      LotSizeCalculate(SLPoints);
      // If the position size is zero then exit and don't submit any orderInit
      if (LotSize == 0)
         return;
      // Submit the order
      int res = OrderSend(Instrument, Command, LotSize, OpenPrice, Slippage, NormalizeDouble(SLPrice, Digits), NormalizeDouble(TPPrice, Digits), OrderNote, MagicNumber, Expiration, OpenColor);
      // If the submission is successful print it in the log and exit the function
      if (res)
      {
         Print("TRADE - OPEN SUCCESS - Order ", res, " submitted: Command ", Command, " Volume ", LotSize, " Open ", OpenPrice, " Stop ", SLPrice, " Take ", TPPrice, " Expiration ", Expiration);
         break;
      }
      // If the submission failed print the error
      else
      {
         Print("TRADE - OPEN FAILED - Order ", res, " submitted: Command ", Command, " Volume ", LotSize, " Open ", OpenPrice, " Stop ", SLPrice, " Take ", TPPrice, " Expiration ", Expiration);
         int Error = GetLastError();
         string ErrorText = GetLastErrorText(Error);
         Print("ERROR - NEW - error sending order, return error: ", Error, " - ", ErrorText);
      }
   }
   return;
}

// Modify Order Function adjusted to handle errors and retry multiple times
void ModifyOrder(int Ticket, double OpenPrice, double SLPrice, double TPPrice)
{
   // Try to select the order by ticket number and print the error if failed
   if (OrderSelect(Ticket, SELECT_BY_TICKET) == false)
   {
      int Error = GetLastError();
      string ErrorText = GetLastErrorText(Error);
      Print("ERROR - SELECT TICKET - error selecting order ", Ticket, " return error: ", Error);
      return;
   }
   // Normalize the digits for stop loss and take profit price
   SLPrice = NormalizeDouble(SLPrice, Digits);
   TPPrice = NormalizeDouble(TPPrice, Digits);
   // Try to submit the changes multiple times
   for (int i = 1; i <= OrderOpRetry; i++)
   {
      // Submit the change
      bool res = OrderModify(Ticket, OpenPrice, SLPrice, TPPrice, 0, Blue);
      // If the change is successful print the result and exit the function
      if (res)
      {
         Print("TRADE - UPDATE SUCCESS - Order ", Ticket, " new stop loss ", SLPrice, " new take profit ", TPPrice);
         break;
      }
      // If the change failed print the error with additional information to troubleshoot
      else
      {
         int Error = GetLastError();
         string ErrorText = GetLastErrorText(Error);
         Print("ERROR - UPDATE FAILED - error modifying order ", Ticket, " return error: ", Error, " - ERROR - ", ErrorText, " - Open=", OpenPrice,
               " Old SL=", OrderStopLoss(), " Old TP=", OrderTakeProfit(),
               " New SL=", SLPrice, " New TP=", TPPrice, " Bid=", MarketInfo(OrderSymbol(), MODE_BID), " Ask=", MarketInfo(OrderSymbol(), MODE_ASK));
      }
   }
   return;
}

// Close Single Order Function adjusted to handle errors and retry multiple times
void CloseOrder(int Ticket, double Lots, double CurrentPrice)
{
   // Try to close the order by ticket number multiple times in case of failure
   for (int i = 1; i <= OrderOpRetry; i++)
   {
      // Send the close command
      bool res = OrderClose(Ticket, Lots, CurrentPrice, Slippage, Red);
      // If the close was successful print the resul and exit the function
      if (res)
      {
         Print("TRADE - CLOSE SUCCESS - Order ", Ticket, " closed at price ", CurrentPrice);
         break;
      }
      // If the close failed print the error
      else
      {
         int Error = GetLastError();
         string ErrorText = GetLastErrorText(Error);
         Print("ERROR - CLOSE FAILED - error closing order ", Ticket, " return error: ", Error, " - ", ErrorText);
      }
   }
   return;
}

// Close All Orders of a specified type
const int OP_ALL = -1; // Constant to define the additional OP_ALL command which is the reference to all type of orders
void CloseAll(int Command)
{
   // If the command is OP_ALL then run the CloseAll function for both BUY and SELL orders
   if (Command == OP_ALL)
   {
      CloseAll(OP_BUY);
      CloseAll(OP_SELL);
      return;
   }
   double ClosePrice = 0;
   // Scan all the orders to close them individually
   // NOTE that the for loop scans from the last to the first, this is because when we close orders the list of orders is updated
   // hence the for loop would skip orders if we scan from first to last
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      // First select the order individually to get its details, if the selection fails print the error and exit the function
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
      {
         Print("ERROR - Unable to select the order - ", GetLastError());
         break;
      }
      // Check if the order is for the current symbol and was opened by the EA and is the type to be closed
      if (OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() && OrderType() == Command)
      {
         // Define the close price
         RefreshRates();
         if (Command == OP_BUY)
            ClosePrice = Bid;
         if (Command == OP_SELL)
            ClosePrice = Ask;
         // Get the position size and the order identifier (ticket)
         double Lots = OrderLots();
         int Ticket = OrderTicket();
         // Close the individual order
         CloseOrder(Ticket, Lots, ClosePrice);
      }
   }
}

// Scan all orders to find the ones submitted by the EA
// NOTE This function is defined as bool because we want to return true if it is successful and false if it fails
bool ScanOrders()
{
   // Scan all the orders, retrieving some of the details
   for (int i = 0; i < OrdersTotal(); i++)
   {
      // If there is a problem reading the order print the error, exit the function and return false
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
      {
         int Error = GetLastError();
         string ErrorText = GetLastErrorText(Error);
         Print("ERROR - Unable to select the order - ", Error, " - ", ErrorText);
         return false;
      }
      // If the order is not for the instrument on chart we can ignore it
      if (OrderSymbol() != Symbol())
         continue;
      // If the order has Magic Number different from the Magic Number of the EA then we can ignore it
      if (OrderMagicNumber() != MagicNumber)
         continue;
      // If it is a buy order then increment the total count of buy orders
      if (OrderType() == OP_BUY)
         TotalOpenBuy++;
      // If it is a sell order then increment the total count of sell orders
      if (OrderType() == OP_SELL)
         TotalOpenSell++;
      // Increment the total orders count
      TotalOpenOrders++;
      // Find what is the open time of the most recent trade and assign it to LastBarTraded
      // this is necessary to check if we already traded in the current candle
      if (OrderOpenTime() > LastBarTraded || LastBarTraded == 0)
         LastBarTraded = OrderOpenTime();
   }
   return true;
}

//********************************************************************************************************

//-DUTO SPECIFIC EXPERT ADVISOR RUNNING FUNCTIONS-//

//********************************************************************************************************

// Initialize 
void InitializeEASettingsComments()
{
   SettingsComments = "==================\n";
   SettingsComments = SettingsComments + "Duto Settings\n";

   string str = "";

   switch (UpperTimeFrame)
   {
     case 0: 
      str = "1 HOUR"; 
      break; 

      case 10: 
      str = "15 MINUTE"; 
      break; 

      case 20: 
      str = "5 MINUTE"; 
      break; 
   }

   SettingsComments = SettingsComments + "Upper Timeframe : " + str + "\n";
   SettingsComments = SettingsComments + "S Trade Ratio Limit : " + BarColorCountThreshold + "\n";
   SettingsComments = SettingsComments + "Bar Count Limit : " + BarCountThreshold + "\n";
   SettingsComments = SettingsComments + "Lookback Count : " + LookBackCount + "\n";

   switch (TradeExitPlot)
   {
     case 6: 
      str = "MACD"; 
      break; 
      case 7: 
      str = "PLOT 2"; 
      break; 
   }

   if (UseTradingHours)
   {
      SettingsComments = SettingsComments + "Valid Trading Hours : " + TradingHourStart + "-" +  + TradingHourEnd + "\n";
   }
   else
   {
      SettingsComments = SettingsComments + "Valid Trading Hours : ALL" + "\n";
   }

   SettingsComments = SettingsComments + "Exit Plot : " + str + "\n";

   Comment(SettingsComments);  
}

void InitializeEACandleComments()
{
   CandleComments = "==================\n";
   CandleComments = CandleComments + "Duto Candle Data\n";
}

void InitializeEAPipComments()
{
   PipComments = "==================\n";
   PipComments = PipComments + "Duto Pip Data\n";
}

ENUM_SIGNAL_ENTRY ReturnSignalEntryToEvaluateEntry()
{  
   // Declaring the variables for the entry check
   SignalEntry = SIGNAL_ENTRY_NEUTRAL;

   //check for an entry
   //SignalEntry = DutoWind_2StrategyEntry();
   SignalEntry = SuddenDarkStrategyEntry();

   return SignalEntry;
}

ENUM_SIGNAL_EXIT ReturnSignalExitToEvaluateExit()

{
   // Declaring the variables for the exit check
   SignalExit = SIGNAL_EXIT_NEUTRAL;

   //check for an exit
   //SignalExit = DutoWind_2StrategyExit();
   SignalExit = SuddenDarkStrategyExit();

   return SignalExit;
}

void LogIndicatorData()
{
   /* //indicator variables
   string indicatorName = "_Custom\\Duto\\macd_color_indicator_plot1_v0.10";
   string duto_chart_indicators = "_Custom\\Duto\\duto_chart_indicators_v0.6";
   string duto_chart_moving_averages = "_Custom\\Duto\\duto_mas";
   string duto_chart_deltas = "_Custom\\Duto\\delta_v0.1";
   string duto_sniper = "_Custom\\Duto\\SchaffTrendCycle";
   string strWriteLine, strWriteLine2 = "";
   int fileHandleIndicatorData;
   int periodArray[] = {60, 15, 5}; */
   
   //if the file exists, then delete it so only the most recent data is included
   if (FileIsExist("duto_indicator_data.csv")) {

      FileDelete("duto_indicator_data.csv");
   } 

   FileCopy("duto_indicator_data_blank.csv", 0, "duto_indicator_data.csv", 0);

   //open the file
   fileHandleIndicatorData = FileOpen("duto_indicator_data.csv", FILE_BIN | FILE_READ | FILE_WRITE | FILE_CSV);

   if (fileHandleIndicatorData < 1)
   {
      Print("can't open file error-", GetLastError());
      //return (0);
   }

   FileSeek(fileHandleIndicatorData, 0, SEEK_END);

   ArrayResize(FastMAHistoryBuffer, Bars + 1);
   ArrayResize(SlowMAHistoryBuffer, Bars + 1);
   ArrayResize(FiveFiftyMAHistoryBuffer, Bars + 1);
   ArrayResize(DeltaCollapsedPosHistoryBuffer, Bars + 1);
   ArrayResize(DeltaCollapsedNegHistoryBuffer, Bars + 1);

   ArrayResize(MacdHistoryBuffer, Bars + 1);
   ArrayResize(MacdPlot2HistoryBuffer, Bars + 1);
   ArrayResize(MacdPlot3HistoryBuffer, Bars + 1);
   ArrayResize(MacdPlot4HistoryBuffer, Bars + 1);

   ArrayResize(SniperHistoryBuffer, Bars + 1);

   ArrayResize(CombinedHistory, Bars + 1);

   for (int i = 0; i <= Bars; i++)
      {
         //build a line of data
         //60
         FastMAHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 0, i);
         CombinedHistory[i][0] = i;//candle index
         CombinedHistory[i][2] = NormalizeDouble(FastMAHistoryBuffer[i], 5);//fast moving average
         
         SlowMAHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 1, i);
         CombinedHistory[i][3] = SlowMAHistoryBuffer[i];//slow moving average

         FiveFiftyMAHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 4, i);
         CombinedHistory[i][4] = FiveFiftyMAHistoryBuffer[i];//550 moving average

         DeltaCollapsedPosHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 5, i);
         DeltaCollapsedNegHistoryBuffer[i] = iCustom(Symbol(),60, duto_chart_indicators, 6, i);

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {
            CombinedHistory[i][5] = -1;//delta collapsed negative
         }
         else {
            CombinedHistory[i][5] = 1;//delta collapsed positive
         }

         MacdHistoryBuffer[i] = iCustom(Symbol(),60, indicatorName, 0, i);
         CombinedHistory[i][6] = MacdHistoryBuffer[i];//macd histogram

         MacdPlot2HistoryBuffer[i] = iCustom(Symbol(),60, indicatorName, 1, i);
         CombinedHistory[i][7] = MacdPlot2HistoryBuffer[i];//plot 2

         MacdPlot3HistoryBuffer[i] = iCustom(Symbol(),60, indicatorName, 2, i);
         CombinedHistory[i][8] = MacdPlot3HistoryBuffer[i];//plot 3

         MacdPlot4HistoryBuffer[i] = iCustom(Symbol(),60, indicatorName, 3, i);
         CombinedHistory[i][9] = MacdPlot4HistoryBuffer[i];//plot 4
      
         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {

            strWriteLine2 = ",Negative";
         }
         else {
            strWriteLine2 = ",Positive";
         }

         SniperHistoryBuffer[i] = iCustom(Symbol(),60, duto_sniper, 0, i);
         CombinedHistory[i][40] = SniperHistoryBuffer[i];//sniper
         
         //build a line of strings based on a line of data
         strWriteLine = 
         i
         + "," + iTime(Symbol(), 60, i) 

         + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
         + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
         + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

         + strWriteLine2
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 7)
         + "";

         //build a line of data
         //15
         FastMAHistoryBuffer[i] = iCustom(Symbol(),15, duto_chart_indicators, 0, i);
         CombinedHistory[i][10] = i;//candle index
         CombinedHistory[i][12] = FastMAHistoryBuffer[i];//fast moving average
         
         SlowMAHistoryBuffer[i] = iCustom(Symbol(),15, duto_chart_indicators, 1, i);
         CombinedHistory[i][13] = SlowMAHistoryBuffer[i];//slow moving average

         FiveFiftyMAHistoryBuffer[i] = iCustom(Symbol(),15, duto_chart_indicators, 4, i);
         CombinedHistory[i][14] = FiveFiftyMAHistoryBuffer[i];//550 moving average

         DeltaCollapsedPosHistoryBuffer[i] = iCustom(Symbol(),15, duto_chart_indicators, 5, i);
         DeltaCollapsedNegHistoryBuffer[i] = iCustom(Symbol(),15, duto_chart_indicators, 6, i);

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {
            CombinedHistory[i][15] = -1;//delta collapsed negative
         }
         else {
            CombinedHistory[i][15] = 1;//delta collapsed positive
         }

         MacdHistoryBuffer[i] = iCustom(Symbol(),15, indicatorName, 0, i);
         CombinedHistory[i][16] = MacdHistoryBuffer[i];//macd histogram

         MacdPlot2HistoryBuffer[i] = iCustom(Symbol(),15, indicatorName, 1, i);
         CombinedHistory[i][17] = MacdPlot2HistoryBuffer[i];//plot 2

         MacdPlot3HistoryBuffer[i] = iCustom(Symbol(),15, indicatorName, 2, i);
         CombinedHistory[i][18] = MacdPlot3HistoryBuffer[i];//plot 3

         MacdPlot4HistoryBuffer[i] = iCustom(Symbol(),15, indicatorName, 3, i);
         CombinedHistory[i][19] = MacdPlot4HistoryBuffer[i];//plot 4

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {

            strWriteLine2 = ",Negative";
         }
         else {
            strWriteLine2 = ",Positive";
         }

         SniperHistoryBuffer[i] = iCustom(Symbol(),15, duto_sniper, 0, i);
         CombinedHistory[i][41] = SniperHistoryBuffer[i];//sniper
         
         //build a line of strings based on a line of data
         strWriteLine = strWriteLine +
         //",Candle " + i
         "," + i
         + "," + iTime(Symbol(), 15, i) 

         + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
         + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
         + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

         + strWriteLine2
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 7)
         + "";

         //build a line of data
         //5
         FastMAHistoryBuffer[i] = iCustom(Symbol(),5, duto_chart_indicators, 0, i);
         CombinedHistory[i][20] = i;//candle index
         CombinedHistory[i][22] = FastMAHistoryBuffer[i];//fast moving average
         
         SlowMAHistoryBuffer[i] = iCustom(Symbol(),5, duto_chart_indicators, 1, i);
         CombinedHistory[i][23] = SlowMAHistoryBuffer[i];//slow moving average

         FiveFiftyMAHistoryBuffer[i] = iCustom(Symbol(),5, duto_chart_indicators, 4, i);
         CombinedHistory[i][24] = FiveFiftyMAHistoryBuffer[i];//550 moving average

         DeltaCollapsedPosHistoryBuffer[i] = iCustom(Symbol(),5, duto_chart_indicators, 5, i);
         DeltaCollapsedNegHistoryBuffer[i] = iCustom(Symbol(),5, duto_chart_indicators, 6, i);

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {
            CombinedHistory[i][25] = -1;//delta collapsed negative
         }
         else {
            CombinedHistory[i][25] = 1;//delta collapsed positive
         }

         MacdHistoryBuffer[i] = iCustom(Symbol(),5, indicatorName, 0, i);
         CombinedHistory[i][26] = MacdHistoryBuffer[i];//macd histogram

         MacdPlot2HistoryBuffer[i] = iCustom(Symbol(),5, indicatorName, 1, i);
         CombinedHistory[i][27] = MacdPlot2HistoryBuffer[i];//plot 2

         MacdPlot3HistoryBuffer[i] = iCustom(Symbol(),5, indicatorName, 2, i);
         CombinedHistory[i][28] = MacdPlot3HistoryBuffer[i];//plot 3

         MacdPlot4HistoryBuffer[i] = iCustom(Symbol(),5, indicatorName, 3, i);
         CombinedHistory[i][29] = MacdPlot4HistoryBuffer[i];//plot 4

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {

            strWriteLine2 = ",Negative";
         }
         else {
            strWriteLine2 = ",Positive";
         }

         SniperHistoryBuffer[i] = iCustom(Symbol(),5, duto_sniper, 0, i);
         CombinedHistory[i][42] = SniperHistoryBuffer[i];//sniper
         
         //build a line of strings based on a line of data
         strWriteLine = strWriteLine +
         "," + i
         + "," + iTime(Symbol(), 5, i) 

         + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
         + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
         + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

         + strWriteLine2
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 7)
         + "";

         //build a line of data
         //1
         FastMAHistoryBuffer[i] = iCustom(Symbol(),1, duto_chart_indicators, 0, i);
         CombinedHistory[i][30] = i;//candle index
         CombinedHistory[i][32] = FastMAHistoryBuffer[i];//fast moving average
         
         SlowMAHistoryBuffer[i] = iCustom(Symbol(),1, duto_chart_indicators, 1, i);
         CombinedHistory[i][33] = SlowMAHistoryBuffer[i];//slow moving average

         FiveFiftyMAHistoryBuffer[i] = iCustom(Symbol(),1, duto_chart_indicators, 4, i);
         CombinedHistory[i][34] = FiveFiftyMAHistoryBuffer[i];//550 moving average

         DeltaCollapsedPosHistoryBuffer[i] = iCustom(Symbol(),1, duto_chart_indicators, 5, i);
         DeltaCollapsedNegHistoryBuffer[i] = iCustom(Symbol(),1, duto_chart_indicators, 6, i);

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {
            CombinedHistory[i][35] = -1;//delta collapsed negative
         }
         else {
            CombinedHistory[i][35] = 1;//delta collapsed positive
         }

         MacdHistoryBuffer[i] = iCustom(Symbol(),1, indicatorName, 0, i);
         CombinedHistory[i][36] = MacdHistoryBuffer[i];//macd histogram

         MacdPlot2HistoryBuffer[i] = iCustom(Symbol(),1, indicatorName, 1, i);
         CombinedHistory[i][37] = MacdPlot2HistoryBuffer[i];//plot 2

         MacdPlot3HistoryBuffer[i] = iCustom(Symbol(),1, indicatorName, 2, i);
         CombinedHistory[i][38] = MacdPlot3HistoryBuffer[i];//plot 3

         MacdPlot4HistoryBuffer[i] = iCustom(Symbol(),1, indicatorName, 3, i);
         CombinedHistory[i][39] = MacdPlot4HistoryBuffer[i];//plot 4

         //Print("MacdPlot4HistoryBuffer[i]: " + NormalizeDouble(MacdPlot4HistoryBuffer[i] ,6)  + " CombinedHistory[i][39]: " + NormalizeDouble(CombinedHistory[i][39] ,6));

         if (DeltaCollapsedPosHistoryBuffer[i] == 2147483647) {

            strWriteLine2 = ",Negative";
         }
         else {
            strWriteLine2 = ",Positive";
         }

         SniperHistoryBuffer[i] = iCustom(Symbol(),1, duto_sniper, 0, i);
         CombinedHistory[i][43] = SniperHistoryBuffer[i];//sniper
         
         //build a line of strings based on a line of data
         strWriteLine = strWriteLine +
         "," + i
         + "," + iTime(Symbol(), 1, i) 

         + "," + DoubleToString(FastMAHistoryBuffer[i], 5)
         + "," + DoubleToString(SlowMAHistoryBuffer[i], 5)
         + "," + DoubleToString(FiveFiftyMAHistoryBuffer[i], 5)

         + strWriteLine2
         
         + "," + DoubleToString(MacdHistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot2HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot3HistoryBuffer[i], 7)
         + "," + DoubleToString(MacdPlot4HistoryBuffer[i], 7)

         //sniper data
         + "," + CombinedHistory[i][40]
         + "," + CombinedHistory[i][41]
         + "," + CombinedHistory[i][42]
         + "," + CombinedHistory[i][43]

         //recent highest and recent lowest data
         + "," + CombinedHistory[i][44]
         + "," + CombinedHistory[i][45]
         + "," + CombinedHistory[i][46]
         + "," + CombinedHistory[i][47]
         + "," + CombinedHistory[i][48]
         + "," + CombinedHistory[i][49]
         + "," + CombinedHistory[i][50]
         + "," + CombinedHistory[i][51]

         + "\r\n";

         //write a line of strings to a file
         FileWriteString(fileHandleIndicatorData, strWriteLine, StringLen(strWriteLine));

         /* //check combined history data with output
         Print("check combined history data with output");
         string combinedHistoryOutput = "";

         for (int col = 0; col <= 39; col++)
         {
            combinedHistoryOutput = combinedHistoryOutput + CombinedHistory[i][col] + ", ";
            //Print(CombinedHistory[i][col] + ", ");
         }

         Print(combinedHistoryOutput); */
      }  

   FileClose(fileHandleIndicatorData); 
}

//********************************************************************************************************

//BEGIN DUTO STRATEGY, ENTRY AND EXIT

//********************************************************************************************************

//DutoWind

//execute the selected strategy
void DutoWind_SelectedStrategy()
{
   DutoWind_2Strategy();
   CandleComments = CandleComments + "Current Strategy : " + CurrentStrategy + "\n";
}

void EvaluateSniper()
{
   int sniperIndex;
   string str;

   switch (UpperTimeFrame)
   {
      case 0: 
      sniperIndex = 0; 
      break; 

      case 10: 
      sniperIndex = 1; 
      break; 

      case 20: 
      sniperIndex = 2; 
      break;  
   }

   if (CombinedHistory[1][(40 + sniperIndex)] == 99)
   {
      str = "HIGH";
      SniperCockedHigh = true;
      SniperCockedLow = false;
      SniperCockedNeutral = false;
   }
   else
   if (CombinedHistory[1][(40 + sniperIndex)] == 0)
   {
      SniperCockedHigh = false;
      SniperCockedLow = true;
      SniperCockedNeutral = false;
      str = "LOW";
   }
   else
   {
      SniperCockedHigh = false;
      SniperCockedLow = false;
      SniperCockedNeutral = true;
      str = "NEUTRAL";
   }
      
   CandleComments = CandleComments + "Sniper Upper Timeframe : " + CombinedHistory[1][(40 + sniperIndex)] + "\n";
   CandleComments = CandleComments + "Sniper Cocked : " + str + "\n";
   CandleComments = CandleComments + "SniperCockedHigh  : " + SniperCockedHigh + "\n";
   CandleComments = CandleComments + "SniperCockedLow  : " + SniperCockedLow  + "\n";
   CandleComments = CandleComments + "SniperCockedNeutral  : " + SniperCockedNeutral  + "\n";
}

void EvaluateSuddenDark()
{
   SuddenDarkStrategy();
}

void DutoWind_2Strategy()
{
   CurrentStrategy = "";

   //BUY 2 STRATEGY SAFETY TRADE
   if (
      (AskThePlots2Strategy((UpperTimeFrame + 6), 1, 1, "ST_BUY_2_STRATEGY") == "SAFETY TRADE BUY 2 STRATEGY") 
      )
   {
      SellStrategyActive = false;
      BuyStrategyActive = true;
      NeutralStrategyActive = false;

      SellSafetyTrade2Strategy = false;
      BuySafetyTrade2Strategy = true;
      NeutralSafetyTrade2Strategy = false;

      //close all sell trades
      CloseAll(OP_SELL);

      /* Print("SAFETY TRADE BUY 2 STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("BuySafetyTrade2Strategy: " + BuySafetyTrade2Strategy);  */    
   }

   //SELL 2 STRATEGY SAFETY TRADE
   if (
      (AskThePlots2Strategy((UpperTimeFrame + 6), 1, 1, "ST_SELL_2_STRATEGY") == "SAFETY TRADE SELL 2 STRATEGY") 
      )
   {
      SellStrategyActive = true;
      BuyStrategyActive = false;
      NeutralStrategyActive = false;

      SellSafetyTrade2Strategy = true;
      BuySafetyTrade2Strategy = false;
      NeutralSafetyTrade2Strategy = false;

      //close all sell trades
      CloseAll(OP_BUY);

      /* Print("SAFETY TRADE SELL 2 STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("SellSafetyTrade2Strategy: " + SellSafetyTrade2Strategy); */    
   }

   //NEUTRAL 2 STRATEGY SAFETY TRADE
   if (
      (AskThePlots2Strategy((UpperTimeFrame + 6), 1, 1, "ST_NEUTRAL_2_STRATEGY") == "SAFETY TRADE NEUTRAL 2 STRATEGY") 
      )
   {
      SellStrategyActive = false;
      BuyStrategyActive = false;
      NeutralStrategyActive = true;

      SellSafetyTrade2Strategy = true;
      BuySafetyTrade2Strategy = false;
      NeutralSafetyTrade2Strategy = true;

      //close all sell trades
      CloseAll(OP_ALL);

      /* Print("SAFETY TRADE NEUTRAL 2 STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("NeutralSafetyTrade2Strategy: " + NeutralSafetyTrade2Strategy); */     
   }
}

ENUM_SIGNAL_ENTRY DutoWind_2StrategyEntry()
{
   //ENTRY LOGIC

   //don't allow new trades to be made outside of the selected trading hours
   if (UseTradingHours && !IsOperatingHours)
   {
      SignalEntry = SIGNAL_ENTRY_NEUTRAL;
      return SignalEntry; // If you are using trading hours and it's not a trading hour don't give an entry signal
   } 

   //BUY ENTRY //ACTIVE 
   if (
         //(AskThePlots2StrategyEntry(36, 1, 1, "BUY_ST_ENTRY") == "ENTER A SAFETY TRADE BUY")
         (AskThePlots2StrategyEntry(UpperTimeFrame + 10 + 6, 1, 1, "BUY_ST_ENTRY") == "ENTER A SAFETY TRADE BUY")
         && BuyStrategyActive == true 
         && BuyTradeActive == false

         && BuySafetyTrade2Strategy == true
      )
   {
      BuyTradeActive = true;

      //Print("ENTER A BUY, BRIGHT RED TO DARK RED. " +
      Print("ENTER A SAFETY TRADE BUY." +
      "SellTradeActive: " + SellTradeActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " BuySafetyTrade2Strategy: " + BuySafetyTrade2Strategy);

      EntryData[1][10] = Ask;
      SignalEntry = SIGNAL_ENTRY_BUY;
   }

   //SELL ENTRY //ACTIVE
  
   if (
         //(AskThePlots2StrategyEntry(36, 1, 1, "SELL_ST_ENTRY") == "ENTER A SAFETY TRADE SELL")
         (AskThePlots2StrategyEntry(UpperTimeFrame + 10 + 6, 1, 1, "SELL_ST_ENTRY") == "ENTER A SAFETY TRADE SELL")
         && SellStrategyActive == true 
         && SellTradeActive == false

         && SellSafetyTrade2Strategy == true
      )
   {
      SellTradeActive = true;

      //Print("ENTER A BUY, BRIGHT RED TO DARK RED. " +
      Print("ENTER A SAFETY TRADE SELL." +
      "SellTradeActive: " + SellTradeActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " SellSafetyTrade2Strategy: " + SellSafetyTrade2Strategy);

      EntryData[0][10] = Bid;
      SignalEntry = SIGNAL_ENTRY_SELL;
   }

   //SignalEntry = SIGNAL_ENTRY_NEUTRAL;

   return SignalEntry;
}

ENUM_SIGNAL_EXIT DutoWind_2StrategyExit()
{ 
   //EXIT LOGIC

   //ACTIVE
   //BUY EXIT
   if (
      //AskThePlots2StrategyExit(37, 1, 1, "BUY_ST_EXIT") == "EXIT A SAFETY TRADE BUY"
      AskThePlots2StrategyExit(UpperTimeFrame + 10 + TradeExitPlot, 1, 1, "BUY_ST_EXIT") == "EXIT A SAFETY TRADE BUY"
      //AskThePlots2StrategyExit(UpperTimeFrame + 10 + 6, 1, 1, "BUY_ST_EXIT") == "EXIT A SAFETY TRADE BUY"
      && BuyStrategyActive == true 
      && BuyTradeActive == true

      && BuySafetyTrade2Strategy == true
      //&& Bid > EntryData[1][10] //current price is greater than the price it was entered at
      )
   {
      BuyTradeActive = false;
      //BuyBrRdDkRdStrategyActive = false;

      Print("Ask/EntryData[0][10] in BUY_ST_EXIT: " + Ask + "/" + EntryData[0][10]);
      Print("EXIT A SAFETY TRADE BUY. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      
      SignalExit = SIGNAL_EXIT_BUY;
   }

   //ACTIVE
   //SELL EXIT
   if (
      //AskThePlots2StrategyExit(37, 1, 1, "SELL_ST_EXIT") == "EXIT A SAFETY TRADE SELL"
      AskThePlots2StrategyExit(UpperTimeFrame + 10 + TradeExitPlot, 1, 1, "SELL_ST_EXIT") == "EXIT A SAFETY TRADE SELL"
      //AskThePlots2StrategyExit(UpperTimeFrame + 10 + 6, 1, 1, "SELL_ST_EXIT") == "EXIT A SAFETY TRADE SELL"
      && SellStrategyActive == true 
      && SellTradeActive == true

      && SellSafetyTrade2Strategy == true
      //&& Bid > EntryData[1][10] //current price is greater than the price it was entered at
      )
   {
      SellTradeActive = false;
      //BuyBrRdDkRdStrategyActive = false;

      Print("Ask/EntryData[0][10] in SELL_ST_EXIT: " + Ask + "/" + EntryData[0][10]);
      Print("EXIT A SAFETY TRADE BUY. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      
      SignalExit = SIGNAL_EXIT_SELL;
   }

   //SignalExit = SIGNAL_EXIT_NEUTRAL;

   return SignalExit;
}

void SuddenDarkStrategy()
{
   OpportunityStrategy = "";

   //BUY SUDDEN DARK
   if (
      (AskThePlotsSuddenDarkStrategy2((UpperTimeFrame + 10 + 8), 1, 1, "SDDN_DK_BUY_BR_RED_DK_RED") == "PLOT INCREASING BRIGHT RED TO DARK RED") 
      && CandleColorHowLong(UpperTimeFrame + 10 + 8, "BR_RED", 3) >= 5
      
      && (AskThePlotsSuddenDarkStrategy2((UpperTimeFrame + 10 + 9), 1, 1, "SDDN_DK_BUY_BR_RED_DK_RED") == "PLOT INCREASING BRIGHT RED TO DARK RED") 
      && CandleColorHowLong(UpperTimeFrame + 10 + 9, "BR_RED", 3) >= 5 

      && GetSniperData("CURRENT_VALUE", 0) < 50
      )
   {
      SellSuddenDarkStrategy = false;
      BuySuddenDarkStrategy = true;
      NeutralSuddenDarkStrategy = false;

      //close all sell trades
      //CloseAll(OP_SELL);

      Print("GetSniperData(): " + GetSniperData("CURRENT_VALUE", 0));

      Print("SUDDEN DARK BUY STRATEGY IN EFFECT. SellSuddenDarkStrategy: " + SellSuddenDarkStrategy + 
      " BuySuddenDarkStrategy: " + BuySuddenDarkStrategy 
      + " NeutralSuddenDarkStrategy: " + NeutralSuddenDarkStrategy);   
   }

   //SELL SUDDEN DARK 
   if (
      (AskThePlotsSuddenDarkStrategy2((UpperTimeFrame + 10 + 8), 1, 1, "SDDN_DK_SELL_BR_GREEN_DK_GREEN") == "PLOT DECREASING BRIGHT GREEN TO DARK GREEN") 
      && CandleColorHowLong(UpperTimeFrame + 10 + 8, "BR_GREEN", 3) >= 5

      && (AskThePlotsSuddenDarkStrategy2((UpperTimeFrame + 10 + 9), 1, 1, "SDDN_DK_SELL_BR_GREEN_DK_GREEN") == "PLOT DECREASING BRIGHT GREEN TO DARK GREEN") 
      && CandleColorHowLong(UpperTimeFrame + 10 + 9, "BR_GREEN", 3) >= 5

      && GetSniperData("CURRENT_VALUE", 0) > 50
      )
   {
      SellSuddenDarkStrategy = true;
      BuySuddenDarkStrategy = false;
      NeutralSuddenDarkStrategy = false;

      //close all sell trades
      //CloseAll(OP_SELL);

      Print("GetSniperData(): " + GetSniperData("CURRENT_VALUE", 0));

      Print("SUDDEN DARK SELL STRATEGY IN EFFECT. SellSuddenDarkStrategy: " + SellSuddenDarkStrategy + 
      " BuySuddenDarkStrategy: " + BuySuddenDarkStrategy 
      + " NeutralSuddenDarkStrategy: " + NeutralSuddenDarkStrategy);   
   }

   //NEUTRAL SUDDEN DARK 
   if (
      (AskThePlotsSuddenDarkStrategy((UpperTimeFrame + 10 + 8), 1, 1, "SDDN_DK_NEUTRAL_STRATEGY") == "SUDDEN DARK NEUTRAL STRATEGY") 
      && (AskThePlotsSuddenDarkStrategy((UpperTimeFrame + 10 + 9), 1, 1, "SDDN_DK_NEUTRAL_STRATEGY") == "SUDDEN DARK NEUTRAL STRATEGY") 
      )
   {
      //SellStrategyActive = false;
      //BuyStrategyActive = true;
      //NeutralStrategyActive = false;

      SellSuddenDarkStrategy = false;
      BuySuddenDarkStrategy = false;
      NeutralSuddenDarkStrategy = true;

      //close all sell trades
      //CloseAll(OP_SELL);

      /* Print("SUDDEN DARK NEUTRAL STRATEGY IN EFFECT. SellSuddenDarkStrategy: " + SellSuddenDarkStrategy + 
      " BuySuddenDarkStrategy: " + BuySuddenDarkStrategy 
      + " NeutralSuddenDarkStrategy: " + NeutralSuddenDarkStrategy);  */
   }
}

ENUM_SIGNAL_ENTRY SuddenDarkStrategyEntry()
{
   //ENTRY LOGIC

   //don't allow new trades to be made outside of the selected trading hours
   if (UseTradingHours && !IsOperatingHours)
   {
      SignalEntry = SIGNAL_ENTRY_NEUTRAL;
      return SignalEntry; // If you are using trading hours and it's not a trading hour don't give an entry signal
   } 

   //SUDDEN DARK BUY ENTRY
   if (    
         (AskThePlotsSuddenDarkEntry(UpperTimeFrame + 10 + 6, 1, 1, "BUY_SDDN_DARK_ENTRY") == "ENTER A SDDN DARK TRADE BUY")
         //&& BuyStrategyActive == true 
         //&& BuyTradeActive == false
         //&& BuySafetyTrade2Strategy == true
         && BuySuddenDarkStrategy == true
      )
   {
      //SellTradeActive = true;
      SuddenDarkBuyActive = true;
      LastHighest = GetLastHighestLowest("HIGHEST", 5, MODE_HIGH, LookBackCount, 1);

      Print("ENTER A SUDDEN DARK TRADE BUY." +
      "SuddenDarkSellActive: " + SuddenDarkSellActive + 
      " SuddenDarkBuyActive: " + SuddenDarkBuyActive + 
      " BuySuddenDarkStrategy: " + BuySuddenDarkStrategy);

      EntryData[1][10] = Ask;
      SignalEntry = SIGNAL_ENTRY_BUY;
   }

   //SUDDEN DARK SELL ENTRY
   if (    
         (AskThePlotsSuddenDarkEntry(UpperTimeFrame + 10 + 6, 1, 1, "SELL_SDDN_DARK_ENTRY") == "ENTER A SDDN DARK TRADE SELL")
         //&& BuyStrategyActive == true 
         //&& BuyTradeActive == false
         //&& BuySafetyTrade2Strategy == true
         && SellSuddenDarkStrategy == true
      )
   {
      //SellTradeActive = true;
      SuddenDarkSellActive = true;
      LastLowest =GetLastHighestLowest("LOWEST", 5, MODE_LOW, LookBackCount, 1);

      Print("ENTER A SUDDEN DARK TRADE SELL." +
      "SuddenDarkSellActive: " + SuddenDarkSellActive + 
      " SuddenDarkBuyActive: " + SuddenDarkBuyActive + 
      " SellSuddenDarkStrategy: " + SellSuddenDarkStrategy);

      EntryData[0][10] = Bid;
      SignalEntry = SIGNAL_ENTRY_SELL;
   }

   //SignalEntry = SIGNAL_ENTRY_NEUTRAL;

   return SignalEntry;
}

ENUM_SIGNAL_EXIT SuddenDarkStrategyExit()
{ 
   //EXIT LOGIC

   //ACTIVE
   //SELL EXIT
   if (
      AskThePlotsSuddenDarkExit(UpperTimeFrame + 10 + 6, 1, 1, "BUY_SDDN_DARK_EXIT") == "EXIT A SDDN DARK TRADE BUY"
      && SuddenDarkBuyActive == true
      //&& SellStrategyActive == true 
      //&& SellTradeActive == true

      //&& SellSafetyTrade2Strategy == true
      //&& Bid > EntryData[1][10] //current price is greater than the price it was entered at
      )
   {
      SuddenDarkBuyActive = false;
      //BuyBrRdDkRdStrategyActive = false;

      Print("EXIT A SUDDEN DARK TRADE BUY." +
      "SuddenDarkSellActive: " + SuddenDarkSellActive + 
      " SuddenDarkBuyActive: " + SuddenDarkBuyActive + 
      " BuyDarkStrategy: " + BuySuddenDarkStrategy);
      
      SignalExit = SIGNAL_EXIT_BUY;
   }

   //ACTIVE
   //SELL EXIT
   if (
      AskThePlotsSuddenDarkExit(UpperTimeFrame + 10 + 6, 1, 1, "SELL_SDDN_DARK_EXIT") == "EXIT A SDDN DARK TRADE SELL"
      && SuddenDarkSellActive == true
      //&& SellStrategyActive == true 
      //&& SellTradeActive == true

      //&& SellSafetyTrade2Strategy == true
      //&& Bid > EntryData[1][10] //current price is greater than the price it was entered at
      )
   {
      SuddenDarkSellActive = false;
      //BuyBrRdDkRdStrategyActive = false;

      Print("EXIT A SUDDEN DARK TRADE SELL." +
      "SuddenDarkSellActive: " + SuddenDarkSellActive + 
      " SuddenDarkBuyActive: " + SuddenDarkBuyActive + 
      " SellSuddenDarkStrategy: " + SellSuddenDarkStrategy);
      
      SignalExit = SIGNAL_EXIT_SELL;
   }

   //SignalExit = SIGNAL_EXIT_NEUTRAL;

   return SignalExit;
}


//functions

/* //hump logic
      CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] > CombinedHistory[CndleStart + 2][Idx]  */ 

string AskThePlots2Strategy(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";
   //Print("AskThePlots2Strategy Idx: " + Idx);
   //Print("AskThePlots2Strategy Idx: " + (UpperTimeFrame + 6));

   /* Print("CombinedHistory[CndleStart][26]: " + CombinedHistory[CndleStart][26]);
   Print("CombinedHistory[CndleStart][27]: " + CombinedHistory[CndleStart][27]);
   Print("CombinedHistory[CndleStart][28]: " + CombinedHistory[CndleStart][28]);
   Print("CombinedHistory[CndleStart][29]: " + CombinedHistory[CndleStart][29]); */

   /* Print("CombinedHistory[CndleStart][36]: " + CombinedHistory[CndleStart][36]);
   Print("CombinedHistory[CndleStart][37]: " + CombinedHistory[CndleStart][37]);
   Print("CombinedHistory[CndleStart][38]: " + CombinedHistory[CndleStart][38]);
   Print("CombinedHistory[CndleStart][39]: " + CombinedHistory[CndleStart][39]); */

   //SAFETY TRADE BUY 2 STRATEGY, ALL DARK GREEN OR BRIGHT GREEN
   if (
      OverallStrategy == "ST_BUY_2_STRATEGY"

      //HIGHER TIME FRAME
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 6)] > 0
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 7)] > 0
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 8)] > 0
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 9)] > 0

      //LOWER TIME FRAME
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 10 + 7)] > 0
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 10 + 8)] > 0
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 10 + 9)] > 0
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("ask the plots PLOT INCREASING DARK GREEN TO BRIGHT GREEN");
      result = "SAFETY TRADE BUY 2 STRATEGY"; 

      /* if (BuySafetyTrade2Strategy == false)
      {
         Print("SAFETY TRADE BUY 2 STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
         + " NeutralStrategyActive: " + NeutralStrategyActive);
         Print("BuySafetyTrade2Strategy: " + BuySafetyTrade2Strategy); 
      }  */
   }

   //SAFETY TRADE SELL 2 STRATEGY, ALL DARK RED OR BRIGHT RED
   if (
      OverallStrategy == "ST_SELL_2_STRATEGY"

      //HIGHER TIME FRAME
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 6)] < 0
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 7)] < 0
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 8)] < 0
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 9)] < 0

      //LOWER TIME FRAME
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 10 + 7)] < 0
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 10 +8)] < 0
      //plot 1 candle 1 is positive
      && CombinedHistory[CndleStart][(UpperTimeFrame + 10 + 9)] < 0
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("ask the plots PLOT INCREASING DARK GREEN TO BRIGHT GREEN");
      result = "SAFETY TRADE SELL 2 STRATEGY";

      /* if (SellSafetyTrade2Strategy == false)
      {
         Print("SAFETY TRADE SELL 2 STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
         + " NeutralStrategyActive: " + NeutralStrategyActive);
         Print("SellSafetyTrade2Strategy: " + SellSafetyTrade2Strategy); 
      }  */
   }

   //SAFETY TRADE NEUTRAL 2 STRATEGY, ALL DARK RED OR BRIGHT RED
   if (
      OverallStrategy == "ST_NEUTRAL_2_STRATEGY"

      && CurrentStrategy != "ST_BUY_2_STRATEGY"
      && CurrentStrategy != "ST_SELL_2_STRATEGY"
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("ask the plots PLOT INCREASING DARK GREEN TO BRIGHT GREEN");
      result = "SAFETY TRADE NEUTRAL 2 STRATEGY"; 

      /* if (NeutralSafetyTrade2Strategy == false)
      {
         Print("SAFETY TRADE NEUTRAL 2 STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
         + " NeutralStrategyActive: " + NeutralStrategyActive);
         Print("NeutralSafetyTrade2Strategy: " + NeutralSafetyTrade2Strategy);  
      }  */
   }

   return result;
}

string AskThePlots2StrategyEntry(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   /* Print("AskThePlots2StrategyEntry Idx: " + Idx);
   Print("BuyStrategyActive: " + BuyStrategyActive);
   Print("OverallStrategy: " + OverallStrategy);
   Print("BuySafetyTrade2Strategy: " + BuySafetyTrade2Strategy);
   Print("Condition 1: " + (CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]));
   Print("Condition 2: " + (CombinedHistory[CndleStart][Idx] > 0 && CombinedHistory[CndleStart + 1][Idx] < 0));
   Print("Condition 3: " + (CombinedHistory[CndleStart][Idx + 1] >  CombinedHistory[CndleStart + 1][Idx + 1])); */

   //ENTRY LOGIC

   //ACTIVE
   //BUY ENTRY SAFETY TRADE
   if (
      BuyStrategyActive == true 
      && OverallStrategy == "BUY_ST_ENTRY"
      && BuySafetyTrade2Strategy == true

      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart][Idx] > 0 && CombinedHistory[CndleStart + 1][Idx] < 0

      //plot 2 is increasing
      && CombinedHistory[CndleStart][Idx + 1] >  CombinedHistory[CndleStart + 1][Idx + 1]

      //this version calculates the ratio between the sum of the bars and the number of the bars
      //&& BarColorCount(Idx, "NEGATIVE") <= 0.000035
      && BarColorCount(Idx, "NEGATIVE") <= BarColorCountThreshold
      // SniperCockedHigh
      )
   { 
      result = "ENTER A SAFETY TRADE BUY";
   }

   //ACTIVE
   //SELL ENTRY SAFETY TRADE
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_ST_ENTRY"
      && SellSafetyTrade2Strategy == true

      //timeframe above
      //commented out because i was missing out on a lot of good trades
      //&& CombinedHistory[CndleStart][26] > CombinedHistory[CndleStart + 1][26]

      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] > 0

      //plot 2 is decreasing
      && CombinedHistory[CndleStart][Idx + 1] <  CombinedHistory[CndleStart + 1][Idx + 1]

      //this version calculates the ratio between the sum of the bars and the number of the bars
      //&& BarColorCount(Idx, "POSITIVE") <= 0.000035
      && BarColorCount(Idx, "POSITIVE") <= BarColorCountThreshold
      // SniperCockedLow
      )
   {  
      result = "ENTER A SAFETY TRADE SELL";
   }

   return result;
}

string AskThePlots2StrategyExit(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   //EXIT LOGIC

   //ACTIVE
   //BUY EXIT SAFETY TRADE
   if (
      OverallStrategy == "BUY_ST_EXIT" 
      
      /* && CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx] 
      && Bid > EntryData[1][10]
      && CombinedHistory[CndleStart][Idx] > 0  */

      && 
         (  //typical take profit exit
            (CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx] 
            && Bid > EntryData[1][10]
            && CombinedHistory[CndleStart][Idx] > 0)
         ||
            //exit if the macd turns to avoid losses
            //CombinedHistory[CndleStart][Idx - 1] < 0
            CombinedHistory[CndleStart][UpperTimeFrame + 10 + 6] < 0
         )
      )
   {
      //Print("Bid: " + Bid + " > EntryData[1][10]: " + EntryData[1][10]);
      result = "EXIT A SAFETY TRADE BUY";
   }

   //ACTIVE
   //SELL EXIT SAFETY TRADE
   if (
      OverallStrategy == "SELL_ST_EXIT" 

      && 
         (  //typical take profit exit
            (CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
            && Ask < EntryData[0][10]
            && CombinedHistory[CndleStart][Idx] < 0)
         ||
            //exit if the macd turns to avoid losses
            //CombinedHistory[CndleStart][Idx - 1] > 0
            CombinedHistory[CndleStart][UpperTimeFrame + 10 + 6] > 0
         )
      )
   {
      //Print("Bid: " + Bid + " > EntryData[1][10]: " + EntryData[1][10]);
      result = "EXIT A SAFETY TRADE SELL";
   }

   return result;
}

string AskThePlotsSuddenDarkStrategy (int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   //BUY STRATEGY, BRIGHT RED TO DARK RED
   if (
      OverallStrategy == "SDDN_DK_BUY_BR_RED_DK_RED"

      //candle 1 greater than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7)
      //candle 1 is negative
      && CombinedHistory[CndleStart][Idx] < 0 
      
      //candle 2 less than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 2 is negative
      && CombinedHistory[CndleStart + 1][Idx] < 0 
      //candle 3 is negative
      && CombinedHistory[CndleStart + 3][Idx] < 0 
      )
   {
      OpportunityStrategy = OverallStrategy; 
      result = "PLOT INCREASING BRIGHT RED TO DARK RED";
   }

   //SELL STRATEGY, BRIGHT GREEN TO DARK GREEN
   if (
      OverallStrategy == "SDDN_DK_SELL_BR_GREEN_DK_GREEN"

      //candle 1 less than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7)
      //candle 1 is positive
      && CombinedHistory[CndleStart][Idx] > 0 
      
      //candle 2 greater than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 2 is positive
      && CombinedHistory[CndleStart + 1][Idx] > 0
      //candle 3 is positive
      && CombinedHistory[CndleStart + 2][Idx] > 0

      /* ///candle 3 greater than or equal to candle 4
      && NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 3][Idx] ,7) 
      //candle 1 is positive
      && CombinedHistory[CndleStart + 2][Idx] > 0 

      //candle 3 greater than or equal to candle 4
      && NormalizeDouble(CombinedHistory[CndleStart + 3][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 4][Idx] ,7) 
      //candle 1 is positive
      && CombinedHistory[CndleStart + 3][Idx] > 0   */ 
      )
    {
      OpportunityStrategy = OverallStrategy; 
      result = "PLOT DECREASING BRIGHT GREEN TO DARK GREEN";
   } 

   //NEUTRAL STRATEGY,
   if (
      OverallStrategy == "SDDN_DK_NEUTRAL_STRATEGY"

      && OpportunityStrategy != "SDDN_DK_BUY_BR_RED_DK_RED"
      && OpportunityStrategy != "SDDN_DK_SELL_BR_GREEN_DK_GREEN"
      )
   {
      OpportunityStrategy = OverallStrategy; 
      //Print("ask the plots PLOT INCREASING DARK GREEN TO BRIGHT GREEN");
      result = "SUDDEN DARK NEUTRAL STRATEGY"; 

      /* if (NeutralSafetyTrade2Strategy == false)
      {
         Print("SAFETY TRADE NEUTRAL 2 STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
         + " NeutralStrategyActive: " + NeutralStrategyActive);
         Print("NeutralSafetyTrade2Strategy: " + NeutralSafetyTrade2Strategy);  
      }  */
   }

   return result;
}

string AskThePlotsSuddenDarkStrategy2 (int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   //BUY STRATEGY, BRIGHT RED TO DARK RED
   if (
      OverallStrategy == "SDDN_DK_BUY_BR_RED_DK_RED"

      //candle 1 greater than candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) > NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7)
      //candle 1 is negative
      && CombinedHistory[CndleStart][Idx] < 0 
      
      //candle 2 greater than candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) > NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7)
      //candle 2 is positive
      && CombinedHistory[CndleStart + 1][Idx] < 0  
      
      //candle 3 less than candle 4
      && NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) < NormalizeDouble(CombinedHistory[CndleStart + 3][Idx] ,7) 
      //candle 3 is negative
      && CombinedHistory[CndleStart + 2][Idx] < 0
      //candle 4 is negative
      && CombinedHistory[CndleStart + 3][Idx] < 0
      )
   {
      OpportunityStrategy = OverallStrategy; 
      result = "PLOT INCREASING BRIGHT RED TO DARK RED";
   }

   //SELL STRATEGY, BRIGHT GREEN TO DARK GREEN
   if (
      OverallStrategy == "SDDN_DK_SELL_BR_GREEN_DK_GREEN"

      //candle 1 less than candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) < NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7)
      //candle 1 is positive
      && CombinedHistory[CndleStart][Idx] > 0

      //candle 2 less than candle 2
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) < NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7)
      //candle 2 is positive
      && CombinedHistory[CndleStart + 1][Idx] > 0  
      
      //candle 3 greater than to candle 4
      && NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) > NormalizeDouble(CombinedHistory[CndleStart + 3][Idx] ,7) 
      //candle 3 is positive
      && CombinedHistory[CndleStart + 2][Idx] > 0
      //candle 4 is positive
      && CombinedHistory[CndleStart + 3][Idx] > 0
      )
    {
      OpportunityStrategy = OverallStrategy; 
      result = "PLOT DECREASING BRIGHT GREEN TO DARK GREEN";
   } 

   //NEUTRAL STRATEGY,
   if (
      OverallStrategy == "SDDN_DK_NEUTRAL_STRATEGY"

      && OpportunityStrategy != "SDDN_DK_BUY_BR_RED_DK_RED"
      && OpportunityStrategy != "SDDN_DK_SELL_BR_GREEN_DK_GREEN"
      )
   {
      OpportunityStrategy = OverallStrategy; 
      //Print("ask the plots PLOT INCREASING DARK GREEN TO BRIGHT GREEN");
      result = "SUDDEN DARK NEUTRAL STRATEGY"; 

      /* if (NeutralSafetyTrade2Strategy == false)
      {
         Print("SAFETY TRADE NEUTRAL 2 STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
         + " NeutralStrategyActive: " + NeutralStrategyActive);
         Print("NeutralSafetyTrade2Strategy: " + NeutralSafetyTrade2Strategy);  
      }  */
   }

   return result;
}

string AskThePlotsSuddenDarkEntry(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   //ENTRY LOGIC

   //ACTIVE
   //BUY ENTRY SAFETY TRADE
   if (
      //1 == 1
      //SellStrategyActive == true 

      OverallStrategy == "BUY_SDDN_DARK_ENTRY"

      //&& SellSafetyTrade2Strategy == true

      //&& CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      //&& CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] > 0

      //plot 2 is decreasing
      //&& CombinedHistory[CndleStart][Idx + 1] <  CombinedHistory[CndleStart + 1][Idx + 1]

      //this version calculates the ratio between the sum of the bars and the number of the bars
      //&& BarColorCount(Idx, "POSITIVE") <= 0.000035
      //&& BarColorCount(Idx, "POSITIVE") <= BarColorCountThreshold
      // SniperCockedLow
      )
   {  
      result = "ENTER A SDDN DARK TRADE BUY";
   }

   //ACTIVE
   //SELL ENTRY SAFETY TRADE
   if (
      //1 == 1
      //SellStrategyActive == true 

      OverallStrategy == "SELL_SDDN_DARK_ENTRY"

      //&& SellSafetyTrade2Strategy == true

      //&& CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      //&& CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] > 0

      //plot 2 is decreasing
      //&& CombinedHistory[CndleStart][Idx + 1] <  CombinedHistory[CndleStart + 1][Idx + 1]

      //this version calculates the ratio between the sum of the bars and the number of the bars
      //&& BarColorCount(Idx, "POSITIVE") <= 0.000035
      //&& BarColorCount(Idx, "POSITIVE") <= BarColorCountThreshold
      // SniperCockedLow
      )
   {  
      result = "ENTER A SDDN DARK TRADE SELL";
   }

   return result;
}

string AskThePlotsSuddenDarkExit(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   //EXIT LOGIC

   //ACTIVE
   //SELL EXIT SUDDEN DARK
   if (
      OverallStrategy == "BUY_SDDN_DARK_EXIT" 

      && 
         (  //typical take profit exit
            (CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx] 
            //&& Bid > EntryData[1][10]
            && CombinedHistory[CndleStart][Idx] > 0)
            /* ||
            (Bid > EntryData[1][10] + 60 * Point) */
            ||
            (CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx] 
            && CombinedHistory[CndleStart][Idx] < 0)
         /* ||
            //exit if the macd turns to avoid losses
            //CombinedHistory[CndleStart][Idx - 1] > 0
            CombinedHistory[CndleStart][UpperTimeFrame + 10 + 6] > 0 */
         )
      )
   {
      ObjectDelete("objLastHighest");
      //Print("Bid: " + Bid + " > EntryData[1][10]: " + EntryData[1][10]);
      result = "EXIT A SDDN DARK TRADE BUY";
   }


   //ACTIVE
   //SELL EXIT SUDDEN DARK
   if (
      OverallStrategy == "SELL_SDDN_DARK_EXIT" 

      && 
         (  //typical take profit exit
            (CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
            //&& Ask < EntryData[0][10]
            && CombinedHistory[CndleStart][Idx] < 0)
            /* ||
            (Ask < EntryData[0][10] - 60 * Point) */
            ||
            (CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
            && CombinedHistory[CndleStart][Idx] > 0)
         /* ||
            //exit if the macd turns to avoid losses
            //CombinedHistory[CndleStart][Idx - 1] > 0
            CombinedHistory[CndleStart][UpperTimeFrame + 10 + 6] > 0 */
         )
      )
   {
      ObjectDelete("objLastLowest");
      //Print("Bid: " + Bid + " > EntryData[1][10]: " + EntryData[1][10]);
      result = "EXIT A SDDN DARK TRADE SELL";
   }

   return result;
}

double BarColorCount (int Idx, string Command){


   int count = 1;
   float barSum = 0.0;

   if (Command == "NEGATIVE" && CombinedHistory[count + 1][Idx] < 0 )
   {
      do 
     { 
      barSum = barSum + CombinedHistory[count + 1][Idx];
      count++; // without this operator an infinite loop will appear! 
     } 
      while(CombinedHistory[count + 1][Idx] < 0);

      Print("Bar sum absolute value: " + MathAbs(barSum));
      Print("Count: " + count);
      Print("Bar sum/BarColorCount: " + NormalizeDouble((MathAbs(barSum)/count) ,6));

      //if(count <= 20)
      if(count <= BarCountThreshold)
      {
         return MathAbs(barSum)/count;
      }
      else
      {
         Print("Rejected for count too high: " + count);
      } 
   }
   else
   if (Command == "POSITIVE" && CombinedHistory[count + 1][Idx] > 0)
   {
      do 
     { 
      barSum = barSum + CombinedHistory[count + 1][Idx];
      count++; // without this operator an infinite loop will appear! 
     } 
      while(CombinedHistory[count + 1][Idx] > 0);

      Print("Bar sum absolute value: " + MathAbs(barSum));
      Print("Count: " + count);
      Print("Bar sum/BarColorCount: " + NormalizeDouble((MathAbs(barSum)/count) ,6));

      //if(count <= 20)
      if(count <= BarCountThreshold)
      {
         return MathAbs(barSum)/count;
      } 
      else
      {
         Print("Rejected for count too high: " + count);
      }     
   }

   /* Print("Bar sum absolute value: " + MathAbs(barSum));
   Print("Returned BarColorCount: " + count);
   Print("Bar sum/BarColorCount: " + NormalizeDouble((MathAbs(barSum)/count) ,6)); */

   return 99.99;
   //return MathAbs(barSum)/count;
}

double GetLastHighestLowest(string command, int timeframe, int timeseries, int count, int start)
{
   double result;
   int returnedCandle;

  if (command == "HIGHEST")
   {
      returnedCandle = iHighest(Symbol(), Period(), MODE_CLOSE, count, start);


      ObjectDelete("objLastHighest");
      ObjectCreate("objLastHighest", OBJ_HLINE, 0, Time[0], High[returnedCandle]);
      ObjectSet("objLastHighest", OBJPROP_COLOR,clrSeaGreen);
      ObjectSet("objLastHighest", OBJPROP_STYLE, STYLE_DASHDOTDOT);

      /* CandleComments = CandleComments + 
      "Last Highest: " + High[returnedCandle] + " at candle " + returnedCandle + "\n"; */

      result = High[returnedCandle];
   }
  else
   if (command == "LOWEST")
   {
      returnedCandle = iLowest(Symbol(), Period(), MODE_CLOSE, count, start);
      ObjectDelete("objLastLowest");
      ObjectCreate("objLastLowest", OBJ_HLINE, 0, Time[0], Low[returnedCandle]);
      ObjectSet("objLastLowest", OBJPROP_COLOR, clrFireBrick);
      ObjectSet("objLastLowest", OBJPROP_STYLE, STYLE_DASHDOTDOT);

      /* CandleComments = CandleComments + 
      "Last Lowest: " + Low[returnedCandle] + " at candle " + returnedCandle + "\n"; */

      result = Low[returnedCandle];
   }
  else
   {
      result == 99.99;
   }

   return result;
}

int CandleColorHowLong(int Idx, string command, int CndleStart)
{
   int count = 0;
   //Print("CandleColorHowLong");
   //Print("command: " + command);

   if (command == "BR_GREEN" && (CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx]))
   {
      do
      { 
         count++;
      } 
      while(
         CombinedHistory[CndleStart + count + 1][Idx] > CombinedHistory[CndleStart + count + 2][Idx]
         && CombinedHistory[CndleStart + count + 1][Idx] > 0
         && CombinedHistory[CndleStart + count + 2][Idx] > 0
         );

         Print("BR_GREEN Count: " + count);
   }

   if (command == "DK_GREEN" && (CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx]))
   {
      do
      { 
         count++;
      } 
      while(
         CombinedHistory[CndleStart + count + 1][Idx] < CombinedHistory[CndleStart + count + 2][Idx]
         && CombinedHistory[CndleStart + count + 1][Idx] > 0
         && CombinedHistory[CndleStart + count + 2][Idx] > 0
         );

         //Print("Count: " + count);
   }

   if (command == "BR_RED" && (CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx]))
   {
      do
      { 
         count++;
      } 
      while(
         CombinedHistory[CndleStart + count + 1][Idx] < CombinedHistory[CndleStart + count + 2][Idx]
         && CombinedHistory[CndleStart + count + 1][Idx] < 0
         && CombinedHistory[CndleStart + count + 2][Idx] < 0
         );

         Print("BR_RED Count: " + count);
   }

   if (command == "DK_RED" && (CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx]))
   {
      do
      { 
         count++;
      } 
      while(
         CombinedHistory[CndleStart + count + 1][Idx] > CombinedHistory[CndleStart + count + 2][Idx]
         && CombinedHistory[CndleStart + count + 1][Idx] < 0
         && CombinedHistory[CndleStart + count + 2][Idx] < 0
         );
   }

   return count;
}

int GetSniperData(string command, int CndleStart)
{
   int result = -99;
   int SniperIndex;

   switch (UpperTimeFrame)
   {
      case 10: 
      SniperIndex = 2; 
      break; 

      case 20: 
      SniperIndex = 3; 
      break;   
   }

   if (command == "CURRENT_VALUE")
   {
      result = CombinedHistory[CndleStart][(40 + SniperIndex)];
   }

   return result;
}
//===============================

void DutoWind_Strategy()
{
   //OVERALL STRATEGY LOGIC

   /* //NEUTRAL STRATEGY CHECK
   if (
      (AskThePlots(1, 1, 1, "NEUTRAL") == "PLOT STEADY NEUTRAL") 
      //&& (AskThePlots(28, 1, 1, "NEUTRAL") == "PLOT STEADY NEUTRAL") 
      //&& (AskThePlots(29, 1, 1, "NEUTRAL") == "PLOT STEADY NEUTRAL")
      && NeutralStrategyActive == false
      )     
   {
      SellStrategyActive = false;
      BuyStrategyActive = false;
      NeutralStrategyActive = true;

      Print("PLOT STEADY NEUTRAL. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
   } */
   
   //BUY STRATEGY CHECK FOR DARK GREEN TO BRIGHT GREEN
   if (
      (AskThePlotsStrategy(27, 1, 1, "BUY_DK_GREEN_BR_GREEN") == "PLOT INCREASING DARK GREEN TO BRIGHT GREEN") 
      && 
      //BuyStrategyActive == false
      BuyDkGrBrGrStrategyActive == false
      )
   {
      SellStrategyActive = false;
      BuyStrategyActive = true;
      NeutralStrategyActive = false;

      BuyDkGrBrGrStrategyActive = true;
      SellBrGrDkGrStrategyActive = false;
      SellDkGrBrRdStrategyActive = false;
      BuyBrRdDkRdStrategyActive = false;
      SellDkRdBrRdStrategyActive = false;
      BuyDkRdBrGrStrategyActive = false;

      //close all sell trades
      CloseAll(OP_SELL);

      Print("A BUY STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT INCREASING DARK GREEN TO BRIGHT GREEN POSITIVE. BuyDkGrBrGrStrategyActive: " + BuyDkGrBrGrStrategyActive);
   }
   else
   //SELL STRATEGY CHECK FOR BRIGHT GREEN TO DARK GREEN
   if (
      (AskThePlotsStrategy(27, 1, 1, "SELL_BR_GREEN_DK_GREEN") == "PLOT DECREASING BRIGHT GREEN TO DARK GREEN") 
      && 
      //SellStrategyActive == false
      SellBrGrDkGrStrategyActive == false
      )
   {
      SellStrategyActive = true;
      BuyStrategyActive = false;
      NeutralStrategyActive = false;

      BuyDkGrBrGrStrategyActive = false;
      SellBrGrDkGrStrategyActive = true;
      SellDkGrBrRdStrategyActive = false;
      BuyBrRdDkRdStrategyActive = false;
      SellDkRdBrRdStrategyActive = false;
      BuyDkRdBrGrStrategyActive = false;

      //close all buy trades
      CloseAll(OP_BUY);

      Print("A SELL STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT DECREASING BRIGHT GREEN TO DARK GREEN POSITIVE. SellBrGrDkGrStrategyActive: " + SellBrGrDkGrStrategyActive);
   }
   else
   //SELL STRATEGY CHECK FOR DARK GREEN TO BRIGHT RED
   if (
      (AskThePlotsStrategy(27, 1, 1, "SELL_DK_GREEN_BR_RED") == "PLOT DECREASING DARK GREEN TO BRIGHT RED") 
      && 
      //SellStrategyActive == false
      SellDkGrBrRdStrategyActive == false
      )
   {
      SellStrategyActive = true;
      BuyStrategyActive = false;
      NeutralStrategyActive = false;

      BuyDkGrBrGrStrategyActive = false;
      SellBrGrDkGrStrategyActive = false;
      SellDkGrBrRdStrategyActive = true;
      BuyBrRdDkRdStrategyActive = false;
      SellDkRdBrRdStrategyActive = false;
      BuyDkRdBrGrStrategyActive = false;

      //close all buy trades
      CloseAll(OP_BUY);

      Print("A SELL STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT DECREASING DARK GREEN TO BRIGHT RED. SellDkGrBrRdStrategyActive: " + SellDkGrBrRdStrategyActive);
   }
   else
   //BUY STRATEGY CHECK FOR BRIGHT RED TO DARK RED
   if (
      (AskThePlotsStrategy(27, 1, 1, "BUY_BR_RED_DK_RED") == "PLOT INCREASING BRIGHT RED TO DARK RED") 
      && BuyBrRdDkRdStrategyActive == false
      //SellStrategyActive == false
      )
   {
      SellStrategyActive = false;
      BuyStrategyActive = true;
      NeutralStrategyActive = false;

      BuyDkGrBrGrStrategyActive = false;
      SellBrGrDkGrStrategyActive = false;
      SellDkGrBrRdStrategyActive = false;
      BuyBrRdDkRdStrategyActive = true;
      SellDkRdBrRdStrategyActive = false;
      BuyDkRdBrGrStrategyActive = false;

      //close all sell trades
      CloseAll(OP_SELL);

      Print("A BUY STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT INCEASING BRIGHT RED TO DARK RED. BuyBrRdDkRdStrategyActive: " + BuyBrRdDkRdStrategyActive);
   }
   else
   //SELL STRATEGY CHECK FOR DARK RED TO BRIGHT RED
   if (
      (AskThePlotsStrategy(27, 1, 1, "SELL_DK_RED_BR_RED") == "PLOT DECREASING DARK RED TO BRIGHT RED") 
      && 
      //SellStrategyActive == false
      SellDkRdBrRdStrategyActive == false
      )
   {
      SellStrategyActive = true;
      BuyStrategyActive = false;
      NeutralStrategyActive = false;

      BuyDkGrBrGrStrategyActive = false;
      SellBrGrDkGrStrategyActive = false;
      SellDkGrBrRdStrategyActive = false;
      BuyBrRdDkRdStrategyActive = false;
      SellDkRdBrRdStrategyActive = true;
      BuyDkRdBrGrStrategyActive = false;

      //close all buy trades
      CloseAll(OP_BUY);

      Print("A SELL STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT DECREASING DARK RED TO BRIGHT RED. SellDkRdBrRdStrategyActive: " + SellDkRdBrRdStrategyActive);
   }
   //BUY STRATEGY CHECK FOR DARK RED TO BRIGHT GREEN
   if (
      (AskThePlotsStrategy(27, 1, 1, "BUY_DK_RED_BR_GREEN") == "PLOT INCREASING DARK RED TO BRIGHT GREEN") 
      && 
      //BuyStrategyActive == false //this line is troublesome. it likely needs to die.
      BuyDkRdBrGrStrategyActive == false
      )
   {
      SellStrategyActive = false;
      BuyStrategyActive = true;
      NeutralStrategyActive = false;

      BuyDkGrBrGrStrategyActive = false;
      SellBrGrDkGrStrategyActive = false;
      SellDkGrBrRdStrategyActive = false;
      BuyBrRdDkRdStrategyActive = false;
      SellDkRdBrRdStrategyActive = false;
      BuyDkRdBrGrStrategyActive = true;

      //close all sell trades
      CloseAll(OP_SELL);

      Print("A BUY STRATEGY IN EFFECT. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive 
      + " NeutralStrategyActive: " + NeutralStrategyActive);
      Print("PLOT INCREASING DARK RED TO BRIGHT GREEN POSITIVE. BuyDkRdBrGrStrategyActive: " + BuyDkRdBrGrStrategyActive);
   }

   //Comment(StringFormat("Show prices\nAsk = %G\nBid = %G = %d",Ask,Bid));
   //Comment("Current Strategy : " + CurrentStrategy);
}

ENUM_SIGNAL_ENTRY DutoWind_Entry()
{
   
   //ENTRY LOGIC

   //don't allow new trades to be made outside of the selected trading hours
   if (UseTradingHours && !IsOperatingHours)
   {
      SignalEntry = SIGNAL_ENTRY_NEUTRAL;
      return SignalEntry; // If you are using trading hours and it's not a trading hour don't give an entry signal
   }     

   /* //BUY ENTRY, DARK GREEN TO BRIGHT GREEN
   //INACTIVE
   if (
         //MACD INCREASING FROM NEGATIVE TO POSITIVE
         //(AskThePlotsEntry(36, 1, 1, "BUY_DK_GREEN_BR_GREEN_ENTRY") == "ENTER A BUY DARK GREEN BRIGHT GREEN") 
         //PLOT 3 INCREASING POSITIVE
         (AskThePlots(38, 1, 1, "BUY_DK_GREEN_BR_GREEN_ENTRY") == "ENTER A BUY DARK GREEN BRIGHT GREEN") 

      && BuyStrategyActive == true 
      && BuyTradeActive == false

      && BuyDkGrBrGrStrategyActive == true
      )
   {
      BuyTradeActive = true;

      Print("ENTER A BUY, DARK GREEN TO BRIGHT GREEN. " +
      "BuyStrategyActive: " + BuyStrategyActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " BuyDkGrBrGrStrategyActive: " + BuyDkGrBrGrStrategyActive);
      //SignalEntry = SIGNAL_ENTRY_BUY;
   }
 */

   //SELL ENTRY, BRIGHT GREEN TO DARK GREEN
   //ACTIVE
   if (
         //(AskThePlots(38, 1, 1, "SELL_BR_GREEN_DK_GREEN_ENTRY") == "ENTER A SELL BRIGHT GREEN DARK GREEN") 
         //MACD DECREASING FROM POSITIVE TO NEGATIVE
         //(AskThePlots(36, 1, 1, "SELL_BR_GREEN_DK_GREEN_ENTRY") == "ENTER A SELL BRIGHT GREEN DARK GREEN")
         //SAFETY TRADE
         (AskThePlotsEntry(36, 1, 1, "SELL_ST_BR_GREEN_DK_GREEN_ENTRY") == "ENTER A ST SELL BRIGHT GREEN DARK GREEN")
      && SellStrategyActive == true 
      && SellTradeActive == false

      && SellBrGrDkGrStrategyActive == true
      )
   {
      /* TradePending = true;
      SellTradePending = true;

      Print("PENDING A SAFETY TRADE SELL, BRIGHT GREEN TO DARK GREEN. " +
      "TradePending: " + TradePending + 
      "SellTradePending: " + SellTradePending + 
      "Bid >= CombinedHistory[0][32]: " + Bid >= CombinedHistory[0][32] + 
      " SellBrGrDkGrStrategyActive: " + SellBrGrDkGrStrategyActive); */
      
      SellTradeActive = true;

      Print("ENTER A SAFETY TRADE SELL, BRIGHT GREEN TO DARK GREEN. " +
      "SellStrategyActive: " + SellStrategyActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " SellBrGrDkGrStrategyActive: " + SellBrGrDkGrStrategyActive);

      //EntryData[0][10] = Ask;
      EntryData[0][10] = Bid;
      SignalEntry = SIGNAL_ENTRY_SELL;
   }

   /* //SELL ENTRY, DARK GREEN TO BRIGHT RED
   //INACTIVE
   if (
         (AskThePlotsEntry(38, 1, 1, "SELL_DK_GREEN_BR_RED_ENTRY") == "ENTER A SELL DARK GREEN BRIGHT RED") 
      && SellStrategyActive == true 
      && SellTradeActive == false

      && SellDkGrBrRdStrategyActive == true
      )
   {
      SellTradeActive = true;

      Print("ENTER A SELL, DARK GREEN TO BRIGHT RED. " +
      "SellStrategyActive: " + SellStrategyActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " SellDkGrBrRdStrategyActive: " + SellDkGrBrRdStrategyActive);
      //SignalEntry = SIGNAL_ENTRY_SELL;
   }
 */

   //BUY ENTRY, BRIGHT RED TO DARK RED
   //ACTIVE
   if (
         //(AskThePlots(38, 1, 1, "BUY_BR_RED_DK_RED_ENTRY") == "ENTER A BUY BRIGHT RED DARK RED") 
         //SAFETY TRADE
         (AskThePlotsEntry(36, 1, 1, "BUY_ST_BR_RED_DK_RED_ENTRY") == "ENTER A ST BUY BRIGHT RED DARK RED")
      && BuyStrategyActive == true 
      && BuyTradeActive == false

      && BuyBrRdDkRdStrategyActive == true
      )
   {
      BuyTradeActive = true;

      //Print("ENTER A BUY, BRIGHT RED TO DARK RED. " +
      Print("ENTER A SAFETY TRADE BUY, BRIGHT RED TO DARK RED. " +
      "SellTradeActive: " + SellTradeActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " BuyBrRdDkRdStrategyActive: " + BuyBrRdDkRdStrategyActive);

      //ntryData[1][10] = Bid;
      EntryData[1][10] = Ask;
      SignalEntry = SIGNAL_ENTRY_BUY;
   }

   /* //SELL ENTRY, DARK RED TO BRIGHT RED
   //INACTIVE
   if (
         (AskThePlotsEntry(38, 1, 1, "SELL_DK_RED_BR_RED_ENTRY") == "ENTER A SELL DARK RED BRIGHT RED") 
      && SellStrategyActive == true 
      && SellTradeActive == false

      && SellDkRdBrRdStrategyActive == true
      )
   {
      SellTradeActive = true;

      Print("ENTER A SELL, DARK RED TO BRIGHT RED. " +
      "SellStrategyActive: " + SellStrategyActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " SellDkRdBrRdStrategyActive: " + SellDkRdBrRdStrategyActive);
      //SignalEntry = SIGNAL_ENTRY_SELL;
   }
 */

   /* //BUY ENTRY, DARK RED TO BRIGHT GREEN
   //INACTIVE
   if (
         (AskThePlotsEntry(38, 1, 1, "BUY_DK_RED_BR_GREEN_ENTRY") == "ENTER A BUY DARK RED BRIGHT GREEN") 
      && BuyStrategyActive == true 
      && BuyTradeActive == false

      && BuyDkRdBrGrStrategyActive == true
      )
   {
      BuyTradeActive = true;

      Print("ENTER A BUY, DARK RED TO BRIGHT GREEN. " +
      "SellStrategyActive: " + SellStrategyActive + 
      " BuyTradeActive: " + BuyTradeActive + 
      " BuyDkRdBrGrStrategyActive: " + BuyDkRdBrGrStrategyActive);
      //SignalEntry = SIGNAL_ENTRY_BUY;
   } */

   //SignalEntry = SIGNAL_ENTRY_NEUTRAL;

   return SignalEntry;
}

ENUM_SIGNAL_EXIT DutoWind_Exit()
{ 
   //EXIT LOGIC

   //BUY EXIT, DARK GREEN TO BRIGHT GREEN
   if (
      AskThePlotsExit(36, 1, 1, "BUY_DK_GREEN_BR_GREEN_EXIT") == "EXIT A BUY DARK GREEN BRIGHT GREEN"
      && BuyStrategyActive == true 
      && BuyTradeActive == true

      && BuyDkGrBrGrStrategyActive == true
      )
   {
      BuyTradeActive = false;
      //BuyDkGrBrGrStrategyActive = false;

      Print("EXIT A BUY, DARK GREEN TO BRIGHT GREEN. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      SignalExit = SIGNAL_EXIT_BUY;
   }

   //ACTIVE
   //NEED TO RENAME THE STRATEGY TO ST
   //SELL EXIT, BRIGHT GREEN TO DARK GREEN
   if (
      //AskThePlotsExit(36, 1, 1, "SELL_BR_GREEN_DK_GREEN_EXIT") == "EXIT A SELL BRIGHT GREEN DARK GREEN"
      AskThePlotsExit(37, 1, 1, "SELL_BR_GREEN_DK_GREEN_EXIT") == "EXIT A SELL BRIGHT GREEN DARK GREEN"
      && SellStrategyActive == true 
      && SellTradeActive == true

      && SellBrGrDkGrStrategyActive == true
      //&& Ask < EntryData[0][10] //current price is less than the price it was entered at
      )
   {
      SellTradeActive = false;
      //SellBrGrDkGrStrategyActive = false;

      Print("Ask/EntryData[0][10] in SELL_BR_GREEN_DK_GREEN_EXIT: " + Ask + "/" + EntryData[0][10]);

      Print("EXIT A SELL, BRIGHT GREEN TO DARK GREEN. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      SignalExit = SIGNAL_EXIT_SELL;
   }

   //SELL EXIT, DARK GREEN TO BRIGHT RED
   if (
      AskThePlotsExit(36, 1, 1, "SELL_DK_GREEN_BR_RED_EXIT") == "EXIT A SELL DARK GREEN BRIGHT RED"
      && SellStrategyActive == true 
      && SellTradeActive == true

      && SellDkGrBrRdStrategyActive == true
      )
   {
      SellTradeActive = false;
      //SellDkGrBrRdStrategyActive = false;

      Print("EXIT A SELL, DARK GREEN TO BRIGHT RED. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      SignalExit = SIGNAL_EXIT_SELL;
   }

   //ACTIVE
   //BUY EXIT, BRIGHT RED TO DARK RED
   if (
      //AskThePlots(36, 1, 1, "BUY_BR_RED_DK_RED_EXIT") == "EXIT A BUY BRIGHT RED DARK RED"
      AskThePlotsExit(37, 1, 1, "BUY_ST_BR_RED_DK_RED_EXIT") == "EXIT A ST BUY BRIGHT RED DARK RED"
      && BuyStrategyActive == true 
      && BuyTradeActive == true

      && BuyBrRdDkRdStrategyActive == true
      //&& Bid > EntryData[1][10] //current price is greater than the price it was entered at
      )
   {
      BuyTradeActive = false;
      //BuyBrRdDkRdStrategyActive = false;

      Print("Ask/EntryData[0][10] in BUY_ST_BR_RED_DK_RED_EXIT: " + Ask + "/" + EntryData[0][10]);
      Print("EXIT A BUY, BRIGHT RED TO DARK RED. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      SignalExit = SIGNAL_EXIT_BUY;
   }

   //SELL EXIT, DARK RED TO BRIGHT RED
   if (
      AskThePlotsExit(36, 1, 1, "SELL_DK_RED_BR_RED_EXIT") == "EXIT A SELL DARK RED BRIGHT RED"
      && SellStrategyActive == true 
      && SellTradeActive == true

      && SellDkRdBrRdStrategyActive == true
      )
   {
      SellTradeActive = false;
      //SellDkRdBrRdStrategyActive = false;

      Print("EXIT A SELL, DARK RED TO BRIGHT RED. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      SignalExit = SIGNAL_EXIT_SELL;
   }

   //BUY EXIT, DARK RED TO BRIGHT GREEN
   if (
      AskThePlotsExit(36, 1, 1, "BUY_DK_RED_BR_GREEN_EXIT") == "EXIT A BUY DARK RED BRIGHT GREEN"
      && BuyStrategyActive == true 
      && BuyTradeActive == true

      && BuyDkRdBrGrStrategyActive == true
      )
   {
      BuyTradeActive = false;
      //BuyDkRdBrGrStrategyActive = false;

      Print("EXIT A BUY, DARK RED TO BRIGHT GREEN. SellStrategyActive: " + SellStrategyActive + " BuyStrategyActive: " + BuyStrategyActive);
      SignalExit = SIGNAL_EXIT_BUY;
   }

   //SignalExit = SIGNAL_EXIT_NEUTRAL;
   return SignalExit;
}

string AskThePlotsStrategy(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   //STRATEGY LOGIC
 
   //BUY STRATEGY, DARK GREEN TO BRIGHT GREEN
   if (
      OverallStrategy == "BUY_DK_GREEN_BR_GREEN"

      //candle 1 greater than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 less than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is positive
      && CombinedHistory[CndleStart][Idx] > 0
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("ask the plots PLOT INCREASING DARK GREEN TO BRIGHT GREEN");
      result = "PLOT INCREASING DARK GREEN TO BRIGHT GREEN"; 
   }
   else
   //SELL STRATEGY, BRIGHT GREEN TO DARK GREEN
   if (
      OverallStrategy == "SELL_BR_GREEN_DK_GREEN"

      //candle 1 less than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 greater than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is positive
      && CombinedHistory[CndleStart][Idx] > 0
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("ask the plots PLOT DECREASING BRIGHT GREEN TO DARK GREEN");
      result = "PLOT DECREASING BRIGHT GREEN TO DARK GREEN";
   }
   else
   //SELL STRATEGY, DARK GREEN TO BRIGHT RED
   if (
      OverallStrategy == "SELL_DK_GREEN_BR_RED"

      //candle 1 less than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 less than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is negative, candle 2 is positive, candle 3 is positive
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] > 0 && CombinedHistory[CndleStart + 2][Idx] > 0
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("TEST TEST PLOT DECREASING DARK GREEN TO BRIGHT RED");
      result = "PLOT DECREASING DARK GREEN TO BRIGHT RED";
   }
   //BUY STRATEGY, BRIGHT RED TO DARK RED
   if (
      OverallStrategy == "BUY_BR_RED_DK_RED"

      //candle 1 greater than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 less than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is negative, candle 2 is negative, candle 3 is negative
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] < 0 && CombinedHistory[CndleStart + 2][Idx] < 0
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("TEST TEST PLOT INCREASING BRIGHT RED TO DARK RED");
      result = "PLOT INCREASING BRIGHT RED TO DARK RED";
   }
   //SELL STRATEGY, DARK RED TO BRIGHT RED
   if (
      OverallStrategy == "SELL_DK_RED_BR_RED"

      //candle 1 less than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 greater than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is negative, candle 2 is negative, candle 3 is negative
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] < 0 && CombinedHistory[CndleStart + 2][Idx] < 0
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("TEST TEST PLOT DECREASING DARK RED TO BRIGHT RED");
      result = "PLOT DECREASING DARK RED TO BRIGHT RED";
   }
   //BUY STRATEGY, DARK RED TO BRIGHT GREEN
   if (
      OverallStrategy == "BUY_DK_RED_BR_GREEN"

      //candle 1 greater than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 greater than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is positive, candle 2 is negative, candle 3 is negative
      && CombinedHistory[CndleStart][Idx] > 0 && CombinedHistory[CndleStart + 1][Idx] < 0 && CombinedHistory[CndleStart + 2][Idx] < 0
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("TEST TEST PLOT INCREASING DARK RED TO BRIGHT GREEN");
      result = "PLOT INCREASING DARK RED TO BRIGHT GREEN";
   }

   return result;
}

string AskThePlotsEntry(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   //ENTRY LOGIC

  /* //BUY ENTRY, DARK GREEN TO BRIGHT GREEN
   if (
      BuyStrategyActive == true 
      && OverallStrategy == "BUY_DK_GREEN_BR_GREEN_ENTRY"

      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      //&& CombinedHistory[CndleStart + 1][Idx] > 0 
      && CombinedHistory[CndleStart][Idx] > 0 && CombinedHistory[CndleStart + 1][Idx] < 0
      )
   {
      Print("ENTRY LOGIC-- ENTER A BUY DARK GREEN BRIGHT GREEN");
      result = "ENTER A BUY DARK GREEN BRIGHT GREEN";
   } */

   //SELL ENTRY, BRIGHT GREEN TO DARK GREEN
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_BR_GREEN_DK_GREEN_ENTRY"

      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      //&& CombinedHistory[CndleStart + 1][Idx] > 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] > 0
      )
   {
      Print("ENTRY LOGIC-- ENTER A SELL BRIGHT GREEN DARK GREEN");
      result = "ENTER A SELL BRIGHT GREEN DARK GREEN";
   }

   //WHICH SELL FOR BRIGHT GREEN TO DARK GREEN TO USE??????

   /* //SELL ENTRY, BRIGHT GREEN TO DARK GREEN
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_BR_GREEN_DK_GREEN_ENTRY"

      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] < 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      //Print("xxxxxxxxxxxxxxxxSELL_BR_GREEN_DK_GREEN_ENTRY");
      result = "ENTER A SELL BRIGHT GREEN DARK GREEN";
   } */

   //ACTIVE
   //SELL ENTRY SAFETY TRADE, BRIGHT GREEN TO DARK GREEN
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_ST_BR_GREEN_DK_GREEN_ENTRY"
      && SellBrGrDkGrStrategyActive == true

      //timeframe above
      //commented out because i was missing out on a lot of good trades
      //&& CombinedHistory[CndleStart][26] < CombinedHistory[CndleStart + 1][26]

      && CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] > 0

      //this version calculates the ratio between the sum of the bars and the number of the bars
      && BarColorCount(Idx, "POSITIVE") <= 0.000035
      )
   {   
      Print("[Idx-10]: " + (26));
      Print("CombinedHistory[CndleStart][26]: " + NormalizeDouble(CombinedHistory[CndleStart][26] ,8));
      Print(BarColorCount(Idx, "POSITIVE"));

      result = "ENTER A ST SELL BRIGHT GREEN DARK GREEN";
   }

   //SELL ENTRY, DARK GREEN TO BRIGHT RED
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_DK_GREEN_BR_RED_ENTRY"

      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] < 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      result = "ENTER A SELL DARK GREEN BRIGHT RED";
   }

   //BUY ENTRY, BRIGHT RED TO DARK RED
   if (
      BuyStrategyActive == true 
      && OverallStrategy == "BUY_BR_RED_DK_RED_ENTRY"

      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] < 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      result = "ENTER A BUY BRIGHT RED DARK RED";
   }

   //ACTIVE
   //BUY ENTRY SAFETY TRADE, BRIGHT RED TO DARK RED
   if (
      BuyStrategyActive == true 
      && OverallStrategy == "BUY_ST_BR_RED_DK_RED_ENTRY"
      && BuyBrRdDkRdStrategyActive == true

      //timeframe above
      //commented out because i was missing out on a lot of good trades
      //&& CombinedHistory[CndleStart][26] > CombinedHistory[CndleStart + 1][26]

      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart][Idx] > 0 && CombinedHistory[CndleStart + 1][Idx] < 0

      //this version calculates the ratio between the sum of the bars and the number of the bars
      && BarColorCount(Idx, "NEGATIVE") <= 0.000035
      )
   {  
      /* Print("[Idx-10]: " + (26));
      Print("CombinedHistory[CndleStart][26]: " + NormalizeDouble(CombinedHistory[CndleStart][26] ,8));
      Print(BarColorCount(Idx, "NEGATIVE"));   */

      result = "ENTER A ST BUY BRIGHT RED DARK RED";
   }

   //SELL ENTRY, DARK RED TO BRIGHT RED
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_DK_RED_BR_RED_ENTRY"

      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] < 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      //Print("TEST TEST ENTER A SELL DARK RED BRIGHT RED");
      result = "ENTER A SELL DARK RED BRIGHT RED";
   }

   //BUY ENTRY, DARK RED TO BRIGHT GREEN
   if (
      BuyStrategyActive == true 
      && OverallStrategy == "BUY_DK_RED_BR_GREEN_ENTRY"

      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] > 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      result = "ENTER A BUY DARK RED BRIGHT GREEN";
   }

   return result;
}

string AskThePlotsExit(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   //EXIT LOGIC

   //BUY EXIT, DARK GREEN TO BRIGHT GREEN
   if (
      OverallStrategy == "BUY_DK_GREEN_BR_GREEN_EXIT" &&
      CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] > 0 
      )
   {
      result = "EXIT A BUY DARK GREEN BRIGHT GREEN";
   }

   //ACTIVE
   //SELL EXIT, BRIGHT GREEN TO DARK GREEN
   if (
      OverallStrategy == "SELL_BR_GREEN_DK_GREEN_EXIT" &&
      CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx]

      //&& Bid < EntryData[0][10]
      && Ask < EntryData[0][10]
      && CombinedHistory[CndleStart + 1][Idx] < 0 
      )
   {
      //Print("Ask: " + Ask + " < EntryData[0][10]: " + EntryData[0][10]);
      result = "EXIT A SELL BRIGHT GREEN DARK GREEN";
   }

   //SELL EXIT, DARK GREEN TO BRIGHT RED
   if (
      OverallStrategy == "SELL_DK_GREEN_BR_RED_EXIT" &&
      CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] < 0 
      )
   {
      result = "EXIT A SELL DARK GREEN BRIGHT RED";
   }

   //ACTIVE
   //BUY EXIT SAFETY TRADE, BRIGHT RED TO DARK RED
   if (
      OverallStrategy == "BUY_ST_BR_RED_DK_RED_EXIT" &&
      CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx] 

      && Bid > EntryData[1][10]
      && CombinedHistory[CndleStart][Idx] > 0 
      )
   {
      //Print("Bid: " + Bid + " > EntryData[1][10]: " + EntryData[1][10]);
      result = "EXIT A ST BUY BRIGHT RED DARK RED";
   }

   //SELL EXIT, DARK RED TO BRIGHT RED
   if (
      OverallStrategy == "SELL_DK_RED_BR_RED_EXIT" &&
      CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] < 0 
      )
   {
      result = "EXIT A SELL DARK RED BRIGHT RED";
   }

   //BUY EXIT, DARK RED TO BRIGHT GREEN
   if (
      OverallStrategy == "BUY_DK_RED_BR_GREEN_EXIT" &&
      CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] > 0 
      )
   {
      result = "EXIT A BUY DARK RED BRIGHT GREEN";
   }

   return result;
}

string AskThePlots(int Idx, int CndleStart, int CmbndHstryCandleLength, string OverallStrategy)
{
   string result = "";

   //STRATEGY LOGIC
 
   //BUY STRATEGY, DARK GREEN TO BRIGHT GREEN
   if (
      OverallStrategy == "BUY_DK_GREEN_BR_GREEN"

      //candle 1 greater than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 less than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is positive
      && CombinedHistory[CndleStart][Idx] > 0
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("ask the plots PLOT INCREASING DARK GREEN TO BRIGHT GREEN");
      result = "PLOT INCREASING DARK GREEN TO BRIGHT GREEN"; 
   }
   else
   //SELL STRATEGY, BRIGHT GREEN TO DARK GREEN
   if (
      OverallStrategy == "SELL_BR_GREEN_DK_GREEN"

      //candle 1 less than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 greater than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is positive
      && CombinedHistory[CndleStart][Idx] > 0
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("ask the plots PLOT DECREASING BRIGHT GREEN TO DARK GREEN");
      result = "PLOT DECREASING BRIGHT GREEN TO DARK GREEN";
   }
   else
   //SELL STRATEGY, DARK GREEN TO BRIGHT RED
   if (
      OverallStrategy == "SELL_DK_GREEN_BR_RED"

      //candle 1 less than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 less than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is negative, candle 2 is positive, candle 3 is positive
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] > 0 && CombinedHistory[CndleStart + 2][Idx] > 0
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("TEST TEST PLOT DECREASING DARK GREEN TO BRIGHT RED");
      result = "PLOT DECREASING DARK GREEN TO BRIGHT RED";
   }
   //BUY STRATEGY, BRIGHT RED TO DARK RED
   if (
      OverallStrategy == "BUY_BR_RED_DK_RED"

      //candle 1 greater than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 less than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is negative, candle 2 is negative, candle 3 is negative
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] < 0 && CombinedHistory[CndleStart + 2][Idx] < 0
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("TEST TEST PLOT INCREASING BRIGHT RED TO DARK RED");
      result = "PLOT INCREASING BRIGHT RED TO DARK RED";
   }
   //SELL STRATEGY, DARK RED TO BRIGHT RED
   if (
      OverallStrategy == "SELL_DK_RED_BR_RED"

      //candle 1 less than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) <= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 greater than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is negative, candle 2 is negative, candle 3 is negative
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] < 0 && CombinedHistory[CndleStart + 2][Idx] < 0
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("TEST TEST PLOT DECREASING DARK RED TO BRIGHT RED");
      result = "PLOT DECREASING DARK RED TO BRIGHT RED";
   }
   //BUY STRATEGY, DARK RED TO BRIGHT GREEN
   if (
      OverallStrategy == "BUY_DK_RED_BR_GREEN"

      //candle 1 greater than or equal to candle 2
      && NormalizeDouble(CombinedHistory[CndleStart][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) 
      //candle 2 greater than or equal to candle 3
      && NormalizeDouble(CombinedHistory[CndleStart + 1][Idx] ,7) >= NormalizeDouble(CombinedHistory[CndleStart + 2][Idx] ,7) 
      //candle 1 is positive, candle 2 is negative, candle 3 is negative
      && CombinedHistory[CndleStart][Idx] > 0 && CombinedHistory[CndleStart + 1][Idx] < 0 && CombinedHistory[CndleStart + 2][Idx] < 0
      )
   {
      CurrentStrategy = OverallStrategy; 
      //Print("TEST TEST PLOT INCREASING DARK RED TO BRIGHT GREEN");
      result = "PLOT INCREASING DARK RED TO BRIGHT GREEN";
   }


   //ENTRY LOGIC

  /* //BUY ENTRY, DARK GREEN TO BRIGHT GREEN
   if (
      BuyStrategyActive == true 
      && OverallStrategy == "BUY_DK_GREEN_BR_GREEN_ENTRY"

      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      //&& CombinedHistory[CndleStart + 1][Idx] > 0 
      && CombinedHistory[CndleStart][Idx] > 0 && CombinedHistory[CndleStart + 1][Idx] < 0
      )
   {
      Print("ENTRY LOGIC-- ENTER A BUY DARK GREEN BRIGHT GREEN");
      result = "ENTER A BUY DARK GREEN BRIGHT GREEN";
   } */

   //SELL ENTRY, BRIGHT GREEN TO DARK GREEN
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_BR_GREEN_DK_GREEN_ENTRY"

      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      //&& CombinedHistory[CndleStart + 1][Idx] > 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] > 0
      )
   {
      Print("ENTRY LOGIC-- ENTER A SELL BRIGHT GREEN DARK GREEN");
      result = "ENTER A SELL BRIGHT GREEN DARK GREEN";
   }

   //WHICH SELL FOR BRIGHT GREEN TO DARK GREEN TO USE??????

   /* //SELL ENTRY, BRIGHT GREEN TO DARK GREEN
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_BR_GREEN_DK_GREEN_ENTRY"

      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] < 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      //Print("xxxxxxxxxxxxxxxxSELL_BR_GREEN_DK_GREEN_ENTRY");
      result = "ENTER A SELL BRIGHT GREEN DARK GREEN";
   } */

   //SELL ENTRY SAFETY TRADE, BRIGHT GREEN TO DARK GREEN
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_ST_BR_GREEN_DK_GREEN_ENTRY"
      && SellBrGrDkGrStrategyActive == true

      //timeframe above
      && CombinedHistory[CndleStart][Idx-10] < CombinedHistory[CndleStart + 1][Idx-10]

      && CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart][Idx] < 0 && CombinedHistory[CndleStart + 1][Idx] > 0

      //this version counts the bars
      //&& BarColorCount(Idx, "POSITIVE") <= 15
      //this version calculates the ratio between the sum of the bars and the number of the bars
      && BarColorCount(Idx, "POSITIVE") <= 0.00002
      )
   {   
      Print(BarColorCount(Idx, "POSITIVE"));  
      //Print("ENTRY LOGIC-- ENTER A SELL BRIGHT GREEN DARK GREEN");
      result = "ENTER A ST SELL BRIGHT GREEN DARK GREEN";
   }

   //SELL ENTRY, DARK GREEN TO BRIGHT RED
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_DK_GREEN_BR_RED_ENTRY"

      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] < 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      result = "ENTER A SELL DARK GREEN BRIGHT RED";
   }

   //BUY ENTRY, BRIGHT RED TO DARK RED
   if (
      BuyStrategyActive == true 
      && OverallStrategy == "BUY_BR_RED_DK_RED_ENTRY"

      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] < 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      result = "ENTER A BUY BRIGHT RED DARK RED";
   }

   //BUY ENTRY SAFETY TRADE, BRIGHT RED TO DARK RED
   if (
      BuyStrategyActive == true 
      && OverallStrategy == "BUY_ST_BR_RED_DK_RED_ENTRY"
      && BuyBrRdDkRdStrategyActive == true

      //timeframe above
      && CombinedHistory[CndleStart][Idx-10] > CombinedHistory[CndleStart + 1][Idx-10]

      && CombinedHistory[CndleStart][Idx] >  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart][Idx] > 0 && CombinedHistory[CndleStart + 1][Idx] < 0

      //this version counts the bars
      //&& BarColorCount(Idx, "NEGATIVE") <= 25
      //this version calculates the ratio between the sum of the bars and the number of the bars
      && BarColorCount(Idx, "NEGATIVE") <= 0.00002
      )
   {   
      Print(BarColorCount(Idx, "NEGATIVE"));  
      //Print("ENTRY LOGIC-- ENTER A SELL BRIGHT GREEN DARK GREEN");
      result = "ENTER A ST BUY BRIGHT RED DARK RED";
   }

   //SELL ENTRY, DARK RED TO BRIGHT RED
   if (
      SellStrategyActive == true 
      && OverallStrategy == "SELL_DK_RED_BR_RED_ENTRY"

      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] < 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      //Print("TEST TEST ENTER A SELL DARK RED BRIGHT RED");
      result = "ENTER A SELL DARK RED BRIGHT RED";
   }

   //BUY ENTRY, DARK RED TO BRIGHT GREEN
   if (
      BuyStrategyActive == true 
      && OverallStrategy == "BUY_DK_RED_BR_GREEN_ENTRY"

      && CombinedHistory[CndleStart][Idx] <  CombinedHistory[CndleStart + 1][Idx]
      && CombinedHistory[CndleStart + 1][Idx] > 0 //don't care if plot 2 is decreasing positive or decreasing negative?
      )
   {
      result = "ENTER A BUY DARK RED BRIGHT GREEN";
   }

   //EXIT LOGIC

   //BUY EXIT, DARK GREEN TO BRIGHT GREEN
   if (
      OverallStrategy == "BUY_DK_GREEN_BR_GREEN_EXIT" &&
      CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] > 0 
      )
   {
      result = "EXIT A BUY DARK GREEN BRIGHT GREEN";
   }

   //SELL EXIT, BRIGHT GREEN TO DARK GREEN
   if (
      OverallStrategy == "SELL_BR_GREEN_DK_GREEN_EXIT" &&
      CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] < 0 
      )
   {
      result = "EXIT A SELL BRIGHT GREEN DARK GREEN";
   }

   //SELL EXIT, DARK GREEN TO BRIGHT RED
   if (
      OverallStrategy == "SELL_DK_GREEN_BR_RED_EXIT" &&
      CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] < 0 
      )
   {
      result = "EXIT A SELL DARK GREEN BRIGHT RED";
   }

   //BUY EXIT, BRIGHT RED TO DARK RED
   if (
      OverallStrategy == "BUY_BR_RED_DK_RED_EXIT" &&
      CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] > 0 
      )
   {
      result = "EXIT A BUY BRIGHT RED DARK RED";
   }

   //BUY EXIT SAFETY TRADE, BRIGHT RED TO DARK RED
   if (
      OverallStrategy == "BUY_ST_BR_RED_DK_RED_EXIT" &&
      CombinedHistory[CndleStart][Idx] < CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart][Idx] > 0 
      )
   {
      result = "EXIT A ST BUY BRIGHT RED DARK RED";
   }

   //SELL EXIT, DARK RED TO BRIGHT RED
   if (
      OverallStrategy == "SELL_DK_RED_BR_RED_EXIT" &&
      CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] < 0 
      )
   {
      result = "EXIT A SELL DARK RED BRIGHT RED";
   }

   //BUY EXIT, DARK RED TO BRIGHT GREEN
   if (
      OverallStrategy == "BUY_DK_RED_BR_GREEN_EXIT" &&
      CombinedHistory[CndleStart][Idx] > CombinedHistory[CndleStart + 1][Idx] 
      && CombinedHistory[CndleStart + 1][Idx] > 0 
      )
   {
      result = "EXIT A BUY DARK RED BRIGHT GREEN";
   }

   return result;
}


//DutoWind

//END DUTO STRATEGY, ENTRY AND EXIT
//===================================================