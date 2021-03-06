//+------------------------------------------------------------------+
//|                                                 bar-reversal.mq4 |
//|                                                     bar-reversal |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "bar-reversal"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input string label0 = "" ; //+--- admin ---+
input int myMagic = 20190331;
input int tracelevel = 2;
input string chartLabel = "bar-reversal";
input double minLunte=10.0;
input double buffer = 5.0;
input double minATRFactor = 2.0;
input int atrPeriod = 8;

input string label1 = "" ; //+--- entry signal ---+
input double lots = 1.0;

static datetime lastBar = NULL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if (Time[0] == lastBar) return;
   lastBar = Time[0];
   
   if (TimeLocal() > StrToTime("17:30") || TimeLocal()<StrToTime("09:00")) {
      closeAll();
      return;
   }
   
   
   bool atrFilter = false;
   if (minATRFactor>0.0) {
      double atr = iATR(_Symbol,PERIOD_CURRENT,atrPeriod,0);
      if ( (High[1]-Low[1]) > (minATRFactor * atr)) atrFilter = true;
   } else {
      atrFilter = true;
   }
         
   
   if (Close[1] < Low[2]) {
      if (Close[1]-Low[1] > minLunte) {
         bool isLong = false;
         for (int i=OrdersTotal();i>=0;i--) {
            if (OrderSelect(i,SELECT_BY_POS)) {
               if (OrderMagicNumber() == myMagic && OrderType()==OP_BUY) isLong=true;
            }
         }
         
         
         
         if (!isLong && atrFilter) {
            double stop = NormalizeDouble(Low[1] - buffer, _Digits);
            double tp   = NormalizeDouble(High[1], _Digits);
            
            if (!OrderSend(_Symbol,OP_BUY,lots,Ask,10,stop,tp,"bar-reversal",myMagic,0,clrGreen)) Print("E0002");
         }
      }
   }
   
   if (Close[1] > High[2]) {
      if (High[1]-Close[1] > minLunte) {
         bool isShort = false;
         for (int i=OrdersTotal();i>=0;i--) {
            if (OrderSelect(i,SELECT_BY_POS)) {
               if (OrderMagicNumber() == myMagic && OrderType()==OP_SELL) isShort=true;
            }
         }
         if (!isShort && atrFilter) {
            double stop = NormalizeDouble(High[1] + buffer, _Digits);
            double tp   = NormalizeDouble(Low[1], _Digits);
            if (!OrderSend(_Symbol,OP_SELL,lots,Bid,10,stop,tp,"bar-reversal",myMagic,0,clrGreen)) Print("E0002");
         }
      }
   }
   
   
  }
//+------------------------------------------------------------------+


void closeAll() {
   for (int i=OrdersTotal();i>=0;i--) {
      if (OrderSelect(i,SELECT_BY_POS)) {
         if (OrderMagicNumber() == myMagic) {
            if (OrderType()==OP_BUY) {
               if (!OrderClose(OrderTicket(),OrderLots(),Bid,10,clrBlack)) Print("E001");
            } else if (OrderType()==OP_SELL) {
               if (!OrderClose(OrderTicket(),OrderLots(),Ask,10,clrBlack)) Print("E001");
            }
         }
      }
   }
}