//+------------------------------------------------------------------+
//|                                                     Turbo.mq5     |
//|                    Torbo Indicator for MT5                        |
//|              ADX + DI Trend Detection / Market Strength           |
//|                                                                  |
//|  Inputs:                                                         |
//|  - ADX Period = 14                                               |
//|  - Threshold = 20                                                |
//|  - Live ADX label = true                                         |
//|  - Text color = White                                            |
//|  - Font size = 12                                                |
//|  - Font = Segoe UI                                               |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copilot"
#property version   "1.30"
#property strict
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

//--- Plot 1: ADX
#property indicator_label1  "ADX"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_width1  2

//--- Plot 2: +DI
#property indicator_label2  "+DI"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLimeGreen
#property indicator_width2  2

//--- Plot 3: -DI
#property indicator_label3  "-DI"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrTomato
#property indicator_width3  2

input int      ADXPeriod         = 14;            // Period
input double   TrendThreshold    = 20.0;          // ADX trend threshold (%)
input bool     ShowLiveADX       = true;          // Show live ADX label
input color    LabelColor        = clrWhite;      // Label text color
input int      LabelFontSize     = 12;            // Font size
input string   LabelFont         = "Segoe UI";   // Font family
input int      LabelShiftBars    = 3;             // Horizontal label offset (bars)

//--- Indicator Buffers
double ADXBuffer[];
double PlusDIBuffer[];
double MinusDIBuffer[];

//--- ADX Handle
int handleADX = INVALID_HANDLE;

//--- Label name
string labelName = "Torbo_ADX_Label";

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, ADXBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, PlusDIBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, MinusDIBuffer, INDICATOR_DATA);

   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, ADXPeriod);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, ADXPeriod);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, ADXPeriod);

   IndicatorSetString(INDICATOR_SHORTNAME, "Torbo");

   handleADX = iADX(_Symbol, _Period, ADXPeriod);
   if(handleADX == INVALID_HANDLE)
   {
      Print("Failed to create ADX handle: ", GetLastError());
      return(INIT_FAILED);
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Calculation                                                      |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < ADXPeriod + 1)
      return 0;

   double adxData[];
   double plusData[];
   double minusData[];
   ArraySetAsSeries(adxData, true);
   ArraySetAsSeries(plusData, true);
   ArraySetAsSeries(minusData, true);

   int copiedADX = CopyBuffer(handleADX, 0, 0, rates_total, adxData);
   int copiedPlus = CopyBuffer(handleADX, 1, 0, rates_total, plusData);
   int copiedMinus = CopyBuffer(handleADX, 2, 0, rates_total, minusData);

   if(copiedADX <= 0 || copiedPlus <= 0 || copiedMinus <= 0)
      return prev_calculated;

   for(int i = 0; i < rates_total; i++)
   {
      ADXBuffer[i] = adxData[i];
      PlusDIBuffer[i] = plusData[i];
      MinusDIBuffer[i] = minusData[i];
   }

   if(ShowLiveADX)
      DrawLiveADXLabel();

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Label drawing                                                     |
//+------------------------------------------------------------------+
void DrawLiveADXLabel()
{
   string text = StringFormat("ADX: %.2f\n+DI: %.2f\n-DI: %.2f",
                              ADXBuffer[0],
                              PlusDIBuffer[0],
                              MinusDIBuffer[0]);

   if(ObjectFind(0, labelName) < 0)
   {
      ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, 40);
   }

   ObjectSetString(0, labelName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, LabelColor);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, LabelFontSize);
   ObjectSetString(0, labelName, OBJPROP_FONT, LabelFont);
}

//+------------------------------------------------------------------+
//| Deinitialization                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(handleADX != INVALID_HANDLE)
      IndicatorRelease(handleADX);

   if(ObjectFind(0, labelName) >= 0)
      ObjectDelete(0, labelName);
}

//+------------------------------------------------------------------+
//| End of file                                                      |
//+------------------------------------------------------------------+
