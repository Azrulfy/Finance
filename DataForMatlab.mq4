//+------------------------------------------------------------------+
//|                                                DataForMatlab.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <Files\FileTxt.mqh>
string    ExtFileName; // ="XXXXXX_PERIOD.CSV";
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {

   CFileTxt     File;
   CFileTxt     SymbollistFile;
   CFileTxt    SymbolspreadFile;
   MqlRates  rates_array[];
   string symbols[];
   int numberOfSymbols = SymbolsList(symbols, false);
   SymbollistFile.Open("SymbolsList.txt",FILE_WRITE,9);
   SymbollistFile.WriteString("{");
   SymbolspreadFile.Open("SymbolsSpread.txt",FILE_WRITE,9);
   SymbolspreadFile.WriteString("{");   
   for(int j = 0; j < numberOfSymbols ; j++ )
   {
      string sSymbol = symbols[j];
      double spread = MarketInfo(sSymbol,MODE_SPREAD);
      int digits = SymbolInfoInteger(sSymbol,SYMBOL_DIGITS);
      SymbollistFile.WriteString("'"+sSymbol+"'");
      SymbolspreadFile.WriteString(spread*(pow(0.1,digits)));
      if (j < numberOfSymbols - 1)
      {
         SymbollistFile.WriteString(",");
         SymbolspreadFile.WriteString(",");         
      }
      Comment("WORKING... wait... ");
      // prepare file name, for example, EURUSD1
      ExtFileName=sSymbol;
      StringConcatenate(ExtFileName,sSymbol,".csv");
      ArraySetAsSeries(rates_array,true);
      int iMaxBar=3000;
      string format="%G,%G,%G,%G,%d";
      int iCod=CopyRates(sSymbol,PERIOD_H4,0,iMaxBar,rates_array);
   
      if(iCod>1)
        {
         // open file
         File.Open(ExtFileName,FILE_WRITE,9);
         for(int i=iCod-1; i>0; i--)
           {
            // prepare a string:
            // 2009.01.05,12:49,1.36770,1.36780,1.36760,1.36760,8
            string sOut=StringFormat("%s",TimeToString(rates_array[i].time,TIME_DATE));
            sOut=sOut+","+TimeToString(rates_array[i].time,TIME_MINUTES);
            sOut=sOut+","+StringFormat(format,
                                       rates_array[i].open,
                                       rates_array[i].high,
                                       rates_array[i].low,
                                       rates_array[i].close,
                                       rates_array[i].tick_volume);
            sOut=sOut+"\n";
            File.WriteString(sOut);
   
           }
         File.Close();
        }
   }
   SymbollistFile.WriteString("}");
   SymbollistFile.Close();
   Comment("OK. ready... ");
  }
  
  int SymbolsList(string &Symbols[], bool Selected)
{
   string SymbolsFileName;
   int Offset, SymbolsNumber;
   
   if(Selected) SymbolsFileName = "symbols.sel";
   else         SymbolsFileName = "symbols.raw";
   
// Открываем файл с описанием символов

   int hFile = FileOpenHistory(SymbolsFileName, FILE_BIN|FILE_READ);
   if(hFile < 0) return(-1);

// Определяем количество символов, зарегистрированных в файле

   if(Selected) { SymbolsNumber = (FileSize(hFile) - 4) / 128; Offset = 116;  }
   else         { SymbolsNumber = FileSize(hFile) / 1936;      Offset = 1924; }

   ArrayResize(Symbols, SymbolsNumber);

// Считываем символы из файла

   if(Selected) FileSeek(hFile, 4, SEEK_SET);
   
   for(int i = 0; i < SymbolsNumber; i++)
   {
      Symbols[i] = FileReadString(hFile, 12);
      FileSeek(hFile, Offset, SEEK_CUR);
   }
   
   FileClose(hFile);
   
// Возвращаем количество считанных инструментов

   return(SymbolsNumber);
}