//+------------------------------------------------------------------+
//|                                                EA31337 framework |
//|                                 Copyright 2016-2021, EA31337 Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

// Includes.
#include "../BufferStruct.mqh"
#include "../Indicator.mqh"
#include "Indi_MA.mqh"

// Structs.
struct ColorLineParams : IndicatorParams {
  // Struct constructor.
  void ColorLineParams(int _shift = 0) {
    itype = INDI_COLOR_LINE;
    max_modes = 2;
    SetDataValueType(TYPE_DOUBLE);
    SetDataValueRange(IDATA_RANGE_MIXED);
    SetCustomIndicatorName("Examples\\ColorLine");
    shift = _shift;
  };
};

/**
 * Implements Color Bars
 */
class Indi_ColorLine : public Indicator {
 protected:
  ColorLineParams params;

 public:
  /**
   * Class constructor.
   */
  Indi_ColorLine(ColorLineParams &_params, ENUM_TIMEFRAMES _tf = PERIOD_CURRENT)
      : Indicator((IndicatorParams)_params, _tf) {
    params = _params;
  };
  Indi_ColorLine(ENUM_TIMEFRAMES _tf = PERIOD_CURRENT) : Indicator(INDI_COLOR_LINE, _tf){};

  /**
   * "Built-in" version of Color Line.
   */
  static double iColorLine(string _symbol, ENUM_TIMEFRAMES _tf, int _mode = 0, int _shift = 0, Indicator *_obj = NULL) {
    INDICATOR_CALCULATE_POPULATE_PARAMS_AND_CACHE_LONG(_symbol, _tf, "Indi_ColorLine");

    Indicator *_indi_ma = Indi_MA::GetCached(_symbol, _tf, 10, 0, MODE_EMA, PRICE_CLOSE);

    return iColorLineOnArray(INDICATOR_CALCULATE_POPULATED_PARAMS_LONG, _mode, _shift, _cache, _indi_ma);
  }

  /**
   * Calculates Color Line on the array of values.
   */
  static double iColorLineOnArray(INDICATOR_CALCULATE_PARAMS_LONG, int _mode, int _shift,
                                  IndicatorCalculateCache<double> *_cache, Indicator *_indi_ma,
                                  bool _recalculate = false) {
    _cache.SetPriceBuffer(_open, _high, _low, _close);

    if (!_cache.HasBuffers()) {
      _cache.AddBuffer<NativeValueStorage<double>>(1 + 1);
    }

    if (_recalculate) {
      _cache.ResetPrevCalculated();
    }

    _cache.SetPrevCalculated(Indi_ColorLine::Calculate(INDICATOR_CALCULATE_GET_PARAMS_LONG, _cache.GetBuffer<double>(0),
                                                       _cache.GetBuffer<double>(1), _indi_ma));

    return _cache.GetTailValue<double>(_mode, _shift);
  }

  /**
   * OnCalculate() method for Color Line indicator.
   */
  static int Calculate(INDICATOR_CALCULATE_METHOD_PARAMS_LONG, ValueStorage<double> &ExtColorLineBuffer,
                       ValueStorage<double> &ExtColorsBuffer, Indicator *ExtMAHandle) {
    static int ticks = 0, modified = 0;
    //--- check data
    int i, calculated = BarsCalculated(ExtMAHandle, rates_total);
    if (calculated < rates_total) {
      // Not all data of ExtMAHandle is calculated.
      return (0);
    }
    //--- first calculation or number of bars was changed
    if (prev_calculated == 0) {
      //--- copy values of MA into indicator buffer ExtColorLineBuffer
      if (CopyBuffer(ExtMAHandle, 0, 0, rates_total, ExtColorLineBuffer, rates_total) <= 0) return (0);
      //--- now set line color for every bar
      for (i = 0; i < rates_total && !IsStopped(); i++) ExtColorsBuffer[i] = GetIndexOfColor(i);
    } else {
      //--- we can copy not all data
      int to_copy;
      if (prev_calculated > rates_total || prev_calculated < 0)
        to_copy = rates_total;
      else {
        to_copy = rates_total - prev_calculated;
        if (prev_calculated > 0) to_copy++;
      }
      //--- copy values of MA into indicator buffer ExtColorLineBuffer
      int copied = CopyBuffer(ExtMAHandle, 0, 0, rates_total, ExtColorLineBuffer, rates_total);
      if (copied <= 0) return (0);

      ticks++;         // ticks counting
      if (ticks >= 5)  // it's time to change color scheme
      {
        ticks = 0;                        // reset counter
        modified++;                       // counter of color changes
        if (modified >= 3) modified = 0;  // reset counter
        switch (modified) {
          case 0:  // first color scheme
            ExtColorLineBuffer.PlotIndexSetInteger(PLOT_LINE_COLOR, 0, Red);
            ExtColorLineBuffer.PlotIndexSetInteger(PLOT_LINE_COLOR, 1, Blue);
            ExtColorLineBuffer.PlotIndexSetInteger(PLOT_LINE_COLOR, 2, Green);
            break;
          case 1:  // second color scheme
            ExtColorLineBuffer.PlotIndexSetInteger(PLOT_LINE_COLOR, 0, Yellow);
            ExtColorLineBuffer.PlotIndexSetInteger(PLOT_LINE_COLOR, 1, Pink);
            ExtColorLineBuffer.PlotIndexSetInteger(PLOT_LINE_COLOR, 2, LightSlateGray);
            break;
          default:  // third color scheme
            ExtColorLineBuffer.PlotIndexSetInteger(PLOT_LINE_COLOR, 0, LightGoldenrod);
            ExtColorLineBuffer.PlotIndexSetInteger(PLOT_LINE_COLOR, 1, Orchid);
            ExtColorLineBuffer.PlotIndexSetInteger(PLOT_LINE_COLOR, 2, LimeGreen);
        }
      } else {
        //--- set start position
        int start = prev_calculated - 1;
        //--- now we set line color for every bar
        for (i = start; i < rates_total && !IsStopped(); i++) ExtColorsBuffer[i] = GetIndexOfColor(i);
      }
    }
    //--- return value of prev_calculated for next call
    return (rates_total);
  }

  static int GetIndexOfColor(const int i) {
    int j = i % 300;
    if (j < 100)  // first index
      return (0);
    if (j < 200)  // second index
      return (1);
    return (2);  // third index
  }

  /**
   * Returns the indicator's value.
   */
  double GetValue(int _mode = 0, int _shift = 0) {
    ResetLastError();
    double _value = EMPTY_VALUE;
    switch (params.idstype) {
      case IDATA_BUILTIN:
        _value = Indi_ColorLine::iColorLine(GetSymbol(), GetTf(), _mode, _shift, THIS_PTR);
        break;
      case IDATA_ICUSTOM:
        _value = iCustom(istate.handle, GetSymbol(), GetTf(), params.GetCustomIndicatorName(), _mode, _shift);
        break;
      default:
        SetUserError(ERR_INVALID_PARAMETER);
    }
    istate.is_ready = _LastError == ERR_NO_ERROR;
    istate.is_changed = false;
    return _value;
  }

  /**
   * Returns the indicator's struct value.
   */
  IndicatorDataEntry GetEntry(int _shift = 0) {
    long _bar_time = GetBarTime(_shift);
    unsigned int _position;
    IndicatorDataEntry _entry(params.max_modes);
    if (idata.KeyExists(_bar_time, _position)) {
      _entry = idata.GetByPos(_position);
    } else {
      _entry.timestamp = GetBarTime(_shift);
      for (int _mode = 0; _mode < (int)params.max_modes; _mode++) {
        _entry.values[_mode] = GetValue(_mode, _shift);
      }
      _entry.SetFlag(INDI_ENTRY_FLAG_IS_VALID, !_entry.HasValue<double>(NULL) && !_entry.HasValue<double>(EMPTY_VALUE));
      if (_entry.IsValid()) {
        _entry.AddFlags(_entry.GetDataTypeFlag(params.GetDataValueType()));
        idata.Add(_entry, _bar_time);
      }
    }
    return _entry;
  }

  /**
   * Returns the indicator's entry value.
   */
  MqlParam GetEntryValue(int _shift = 0, int _mode = 0) {
    MqlParam _param = {TYPE_DOUBLE};
    _param.double_value = GetEntry(_shift)[_mode];
    return _param;
  }
};
