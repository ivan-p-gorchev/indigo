// Top view

#define TOP_CENTER_SERVO    0x00      // Top center servo motor is deriven by Polulo channel 0x00
#define BOTTOM_RIGHT_SERVO  0x01      // Bottom right servo motor is deriven by Polulo channel 0x01
#define BOTTOM_LEFT_SERVO   0x02      // Bottom left servo motor is deriven by Polulo channel 0x02

// Deffinition of serial commands, regarding Compact Protocol

#define COMPACT_PROTOCOL (1)

#ifdef COMPACT_PROTOCOL

  #define SET_TARGET        0x84      //Format: SET_TARGET, channel number, target low 7 bits, target high 7 bits
  #define SET_SPEED         0x87      //Format: SET_SPEED, channel number, speed low bits, speed high bits (0,25us)/(10ms)
  #define SET_ACCELERATION  0x89      //Format: SET_ACCELERATION, channel number, acceleration low bits, acceleration high bits (0,25us)/(10ms)/(80ms)
  #define GET_POSITION      0x90      //Format: GET_POSITION, channel number, returns: position low 8 bits, position high 8 bits
  #define GET_ERRORS        0xA1      //Format: GET_ERRORS, returns: error bits 0-7, error bits 8-15
  #define GO_HOME           0xA2      //Format: GO_HOME

#endif
