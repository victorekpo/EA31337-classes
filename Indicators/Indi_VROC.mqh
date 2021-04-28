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

// Structs.
struct VROCParams : IndicatorParams {
  unsigned int period;
  ENUM_APPLIED_VOLUME applied_volume;
  // Struct constructor.
  void VROCParams(unsigned int _period = 25, ENUM_APPLIED_VOLUME _applied_volume = VOLUME_TICK, int _shift = 0,
                  ENUM_TIMEFRAMES _tf = PERIOD_CURRENT) {
    applied_volume = _applied_volume;
    itype = INDI_VROC;
    max_modes = 1;
    period = _period;
    SetDataValueType(TYPE_DOUBLE);
    SetDataValueRange(IDATA_RANGE_MIXED);
    SetCustomIndicatorName("Examples\\VROC");
    SetDataSourceType(IDATA_ICUSTOM);
    shift = _shift;
    tf = _tf;
    tfi = Chart::TfToIndex(_tf);
  };
  void VROCParams(VROCParams &_params, ENUM_TIMEFRAMES _tf = PERIOD_CURRENT) {
    this = _params;
    tf = _tf;
  };
};

/**
 * Implements the Volume Rate of Change indicator.
 */
class Indi_VROC : public Indicator {
 protected:
  VROCParams params;

 public:
  /**
   * Class constructor.
   */
  Indi_VROC(VROCParams &_params) : params(_params.applied_volume), Indicator((IndicatorParams)_params) {
    params = _params;
  };
  Indi_VROC(ENUM_TIMEFRAMES _tf = PERIOD_CURRENT) : Indicator(INDI_VROC, _tf) { params.tf = _tf; };

  /**
   * Returns the indicator's value.
   */
  double GetValue(int _mode = 0, int _shift = 0) {
    ResetLastError();
    double _value = EMPTY_VALUE;
    switch (params.idstype) {
      case IDATA_ICUSTOM:
        _value = iCustom(istate.handle, GetSymbol(), GetTf(), params.GetCustomIndicatorName(),
                         /*[*/ GetPeriod(), GetAppliedVolume() /*]*/, _mode, _shift);
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

  /* Getters */

  /**
   * Get period volume.
   */
  unsigned int GetPeriod() { return params.period; }

  /**
   * Get applied volume.
   */
  ENUM_APPLIED_VOLUME GetAppliedVolume() { return params.applied_volume; }

  /* Setters */

  /**
   * Set period.
   */
  void SetPeriod(ENUM_APPLIED_VOLUME _period) {
    istate.is_changed = true;
    params.period = _period;
  }

  /**
   * Set applied volume.
   */
  void SetAppliedVolume(ENUM_APPLIED_VOLUME _applied_volume) {
    istate.is_changed = true;
    params.applied_volume = _applied_volume;
  }
};
