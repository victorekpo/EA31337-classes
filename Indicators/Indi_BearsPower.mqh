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
#include "../Indicator.mqh"

#ifndef __MQL4__
// Defines global functions (for MQL4 backward compability).
double iBearsPower(string _symbol, int _tf, int _period, int _ap, int _shift) {
  return Indi_BearsPower::iBearsPower(_symbol, (ENUM_TIMEFRAMES)_tf, _period, (ENUM_APPLIED_PRICE)_ap, _shift);
}
#endif

// Structs.
struct BearsPowerParams : IndicatorParams {
  unsigned int period;
  ENUM_APPLIED_PRICE applied_price;
  // Struct constructors.
  void BearsPowerParams(unsigned int _period = 13, ENUM_APPLIED_PRICE _ap = PRICE_CLOSE, int _shift = 0)
      : period(_period), applied_price(_ap), IndicatorParams(INDI_BEARS, 1, TYPE_DOUBLE) {
    shift = _shift;
    SetDataValueRange(IDATA_RANGE_MIXED);
    SetCustomIndicatorName("Examples\\Bears");
  };
};

/**
 * Implements the Bears Power indicator.
 */
class Indi_BearsPower : public Indicator<BearsPowerParams> {
 public:
  /**
   * Class constructor.
   */
  Indi_BearsPower(BearsPowerParams &_p, IndicatorBase *_indi_src = NULL) : Indicator<BearsPowerParams>(_p, _indi_src) {}
  Indi_BearsPower(ENUM_TIMEFRAMES _tf) : Indicator(INDI_BEARS, _tf) {}

  /**
   * Returns the indicator value.
   *
   * @docs
   * - https://docs.mql4.com/indicators/ibearspower
   * - https://www.mql5.com/en/docs/indicators/ibearspower
   */
  static double iBearsPower(string _symbol, ENUM_TIMEFRAMES _tf, unsigned int _period,
                            ENUM_APPLIED_PRICE _applied_price,  // (MT5): not used
                            int _shift = 0, IndicatorBase *_obj = NULL) {
#ifdef __MQL4__
    return ::iBearsPower(_symbol, _tf, _period, _applied_price, _shift);
#else  // __MQL5__
    int _handle = Object::IsValid(_obj) ? _obj.Get<int>(IndicatorState::INDICATOR_STATE_PROP_HANDLE) : NULL;
    double _res[];
    ResetLastError();
    if (_handle == NULL || _handle == INVALID_HANDLE) {
      if ((_handle = ::iBearsPower(_symbol, _tf, _period)) == INVALID_HANDLE) {
        SetUserError(ERR_USER_INVALID_HANDLE);
        return EMPTY_VALUE;
      } else if (Object::IsValid(_obj)) {
        _obj.SetHandle(_handle);
      }
    }
    if (Terminal::IsVisualMode()) {
      // To avoid error 4806 (ERR_INDICATOR_DATA_NOT_FOUND),
      // we check the number of calculated data only in visual mode.
      int _bars_calc = BarsCalculated(_handle);
      if (GetLastError() > 0) {
        return EMPTY_VALUE;
      } else if (_bars_calc <= 2) {
        SetUserError(ERR_USER_INVALID_BUFF_NUM);
        return EMPTY_VALUE;
      }
    }
    if (CopyBuffer(_handle, 0, _shift, 1, _res) < 0) {
      return EMPTY_VALUE;
    }
    return _res[0];
#endif
  }

  /**
   * Returns the indicator's value.
   */
  double GetValue(int _mode = 0, int _shift = 0) {
    ResetLastError();
    double _value = EMPTY_VALUE;
    switch (iparams.idstype) {
      case IDATA_BUILTIN:
        istate.handle = istate.is_changed ? INVALID_HANDLE : istate.handle;
        _value = _value = iBearsPower(GetSymbol(), GetTf(), GetPeriod(), GetAppliedPrice(), _shift, THIS_PTR);
        break;
      case IDATA_ICUSTOM:
        _value = iCustom(istate.handle, GetSymbol(), GetTf(), iparams.GetCustomIndicatorName(), /*[*/ GetPeriod() /*]*/,
                         _mode, _shift);
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
    IndicatorDataEntry _entry(iparams.GetMaxModes());
    if (idata.KeyExists(_bar_time, _position)) {
      _entry = idata.GetByPos(_position);
    } else {
      _entry.timestamp = GetBarTime(_shift);
      for (int _mode = 0; _mode < (int)iparams.GetMaxModes(); _mode++) {
        _entry.values[_mode] = GetValue(_mode, _shift);
      }
      _entry.SetFlag(INDI_ENTRY_FLAG_IS_VALID, IsValidEntry(_entry));
      if (_entry.IsValid()) {
        _entry.AddFlags(_entry.GetDataTypeFlag(iparams.GetDataValueType()));
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
    _param.double_value = GetEntry(_shift).values[_mode].GetDbl();
    return _param;
  }

  /**
   * Checks if indicator entry values are valid.
   */
  virtual bool IsValidEntry(IndicatorDataEntry &_entry) {
    return !_entry.HasValue((double)NULL) && !_entry.HasValue(EMPTY_VALUE);
  }

  /* Getters */

  /**
   * Get period value.
   */
  unsigned int GetPeriod() { return iparams.period; }

  /**
   * Get applied price value.
   *
   * Note: Not used in MT5.
   */
  ENUM_APPLIED_PRICE GetAppliedPrice() { return iparams.applied_price; }

  /* Setters */

  /**
   * Set period value.
   */
  void SetPeriod(unsigned int _period) {
    istate.is_changed = true;
    iparams.period = _period;
  }

  /**
   * Set applied price value.
   *
   * Note: Not used in MT5.
   */
  void SetAppliedPrice(ENUM_APPLIED_PRICE _applied_price) {
    istate.is_changed = true;
    iparams.applied_price = _applied_price;
  }
};
