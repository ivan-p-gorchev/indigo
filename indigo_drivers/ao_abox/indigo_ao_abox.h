// Copyright (c) 2020 Ivan P. Gorchev
// All rights reserved.
//
// You can use this software under the terms of 'INDIGO Astronomy
// open-source license' (see LICENSE.md).
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS 'AS IS' AND ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// version history
// 1.0 by Ivan P. Gorchev

/** INDIGO Acquisition box AO driver
 \file indigo_ao_sx.h
 */

#ifndef ao_abox_h
#define ao_abox_h

#include <indigo/indigo_driver.h>
#include <indigo/indigo_ao_driver.h>
#include <indigo/indigo_guider_driver.h>

#ifdef __cplusplus
extern "C" {
#endif

// Deffinition of serial commands, regarding Compact Protocol

#define SET_TARGET        0x84      //Format: SET_TARGET, channel number, target low 7 bits, target high 7 bits
                                    //Response: None
#define SET_SPEED         0x87      //Format: SET_SPEED, channel number, speed low bits, speed high bits (0,25us)/(10ms)
                                    //Response: None
#define SET_ACCELERATION  0x89      //Format: SET_ACCELERATION, channel number, acceleration low bits, acceleration high bits (0,25us)/(10ms)/(80ms)
                                    //Response: None
#define GET_POSITION      0x90      //Format: GET_POSITION, channel number
                                    //Response: Position low 8 bits, position high 8 bits
#define GET_ERRORS        0xA1      //Format: GET_ERRORS
                                    //Response: Error low 8 bits, error high 8 bits
#define GO_HOME           0xA2      //Format: GO_HOME

#define RESPONSE_SIZE     0x02      // Regarding Compact Protocol, response is always 2 bytes


/** Create mount abox AO device instance
 */

extern indigo_result indigo_ao_abox(indigo_driver_action action, indigo_driver_info *info);

#ifdef __cplusplus
}
#endif

#endif /* ao_abox_h */
