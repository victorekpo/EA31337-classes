//+------------------------------------------------------------------+
//|                                                EA31337 framework |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
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

/**
 * @file
 * Includes Indi_Drawer's structs.
 */

// Includes.
#include "../Indicator.struct.h"

// Structs.

/* Structure for indicator parameters. */
struct DrawerParams : IndicatorParams {
  unsigned int period;
  ENUM_APPLIED_PRICE applied_price;

  DrawerParams(unsigned int _period = 10, ENUM_APPLIED_PRICE _ap = PRICE_CLOSE) : period(_period), applied_price(_ap) {
    itype = INDI_DRAWER;
    max_modes = 0;
    SetCustomIndicatorName("Examples\\Drawer");
    SetDataValueType(TYPE_DOUBLE);
  };
  void DrawerParams(DrawerParams &_p, ENUM_TIMEFRAMES _tf = PERIOD_CURRENT) {
    this = _p;
    tf = _tf;
  };
  // Serializers.
  SERIALIZER_EMPTY_STUB;
  SerializerNodeType Serialize(Serializer &s);
};

/* Method to serialize DrawerParams structure. */
SerializerNodeType DrawerParams::Serialize(Serializer &s) {
  s.Pass(THIS_REF, "period", period);
  s.PassEnum(THIS_REF, "applied_price", applied_price);
  s.Enter(SerializerEnterObject);
  IndicatorParams::Serialize(s);
  s.Leave();
  return SerializerNodeObject;
}

// Storing calculated average gain and loss for SMMA calculations.
struct DrawerGainLossData {
  double avg_gain;
  double avg_loss;
  DrawerGainLossData() { avg_gain = avg_loss = 0.0; }
};
