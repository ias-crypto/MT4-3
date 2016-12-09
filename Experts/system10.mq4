//+------------------------------------------------------------------+
//|                                                     system10.mq4 |
//|                                                    morning range |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "morning range"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Include/JensUtils.mqh";

extern int rangeStartHour = 8;
extern int rangeStartMinute = 0;
extern int rangeEndHour = 9;
extern int rangeEndMinute = 15;


extern int handelStartHour = 9;
extern int handelStartMinute = 15;
extern int handelSchlussHour = 21;
extern int handelSchlussMinute = 58;

extern int myMagic = 20161204;
extern double fixedTakeProfit = 0.0;
extern double initialStop = 30.0;
extern double buffer = 5.0;
static datetime lastTradeTime = NULL;
extern int lotDigits=1;
extern double riskSize=0.01;

string screenRect = "Range";

double rangeTop = 0.0;
double rangeBottom = 0.0;
int rangeDay = -1;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   //range muss vor handelsstart liegen
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
     if (!isHandelszeit(handelStartHour, handelStartMinute, handelSchlussHour, handelSchlussMinute)) {
            closeAllPendingOrders(myMagic);
            closeAllOpenOrders(myMagic);
            return;
      }
      
      if (rangeDay != TimeDay(TimeLocal())) {
         string rangeStartTimeString = StringFormat("%4i.%02i.%02i %02i:%02i",TimeYear(TimeLocal()),TimeMonth(TimeLocal()), TimeDay(TimeLocal()), rangeStartHour,rangeStartMinute);
         string rangeEndTimeString = StringFormat("%4i.%02i.%02i %02i:%02i",TimeYear(TimeLocal()),TimeMonth(TimeLocal()), TimeDay(TimeLocal()), rangeEndHour,rangeEndMinute);
         datetime rangeStartDt = StrToTime(rangeStartTimeString);
         datetime rangeEndDt = StrToTime(rangeEndTimeString);
         
         int rangeStartIndex = iBarShift(Symbol(),PERIOD_CURRENT,rangeStartDt,true);
         int rangeEndIndex = iBarShift(Symbol(),PERIOD_CURRENT,rangeEndDt,true);
         
         
         Print("startIndex: " + rangeStartIndex);
         Print("stop index:" + rangeEndIndex);
         
         int highIndex = iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH, (rangeStartIndex-rangeEndIndex),rangeEndIndex);
         rangeTop = High[highIndex];
         int lowIndex = iLowest(Symbol(),PERIOD_CURRENT,MODE_LOW,(rangeStartIndex-rangeEndIndex),rangeEndIndex);
         rangeBottom = Low[lowIndex];
         
         PrintFormat("highIndex:%i, lowIndex: %i, rangeTop: %.2f, rangeBottom:%.2f",highIndex, lowIndex, rangeTop,rangeBottom);
         
         rangeDay = TimeDay(TimeLocal());
         
         ObjectDelete(screenRect);
   
         ObjectCreate(screenRect, OBJ_RECTANGLE, 0,rangeStartDt,rangeTop,rangeEndDt,rangeBottom);
         ObjectSet(screenRect, OBJPROP_BACK, true);
         ObjectSet(screenRect, OBJPROP_COLOR, clrBlue);
         ObjectSet(screenRect, OBJPROP_STYLE, STYLE_SOLID);         
      }
      
      if (  0 == OrdersTotal() && 
            Bid < rangeTop &&
            Ask > rangeBottom) {
            
         double stopLoss = rangeBottom + ((rangeTop-rangeBottom)/2);
         if (initialStop > 0 && stopLoss > rangeTop - initialStop) {
            stopLoss = rangeTop - initialStop;
         } 
         double tp = 0;
         if (fixedTakeProfit > 0) {
            tp = rangeTop + buffer + fixedTakeProfit;
         }
         double lots = lotsByRisk(rangeTop + buffer - stopLoss,riskSize,lotDigits);
         PrintFormat("buy: price=%.2f,,stop=%.2f,tp=%.2f,lots=%.2f",rangeTop+buffer,stopLoss,tp,lots);
         if (lots>0) {
            OrderSend(Symbol(),OP_BUYSTOP,lots,rangeTop + buffer, 2, stopLoss ,tp,NULL,myMagic,0,clrGreen);      
         }
         
         stopLoss = rangeBottom + ((rangeTop-rangeBottom)/2);
         if (initialStop > 0 && stopLoss < rangeBottom + initialStop) {
            stopLoss = rangeBottom + initialStop;
         }
         tp = 0;
         if (fixedTakeProfit > 0) {
            tp = rangeTop - buffer - fixedTakeProfit;
         }
         lots = lotsByRisk(stopLoss - rangeBottom - buffer,riskSize,lotDigits);
         PrintFormat("sell: price=%.2f,rangeBottom=%.2f,stop=%.2f,tp=%.2f",rangeBottom - buffer,rangeBottom, stopLoss,tp);
         if (lots>0) {
            OrderSend(Symbol(),OP_SELLSTOP,lots,rangeBottom - buffer, 2, stopLoss ,tp,NULL,myMagic,0,clrRed);      
         }
      }
      
   
  }
//+------------------------------------------------------------------+

