// Uses POSIX functions to send and receive data from a Maestro.
// NOTE: The Maestro's serial mode must be set to "USB Dual Port".
// NOTE: You must change the 'const char * device' line below.

#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include "a-box_header.h"

#ifdef _WIN32
#define O_NOCTTY 0
#else
#include <termios.h>
#endif

// Gets the errors of a Maestro device.
// See the "Serial Servo Commands" section of the user's guide.
int maestroGetErrors(int fd)
{
  printf("Reading currnet errors...\n");
  // compact protocol
   unsigned char command[] = {GET_ERRORS};
  // Pololu protocol
  //unsigned char command[] = {0xAA, 0x0C, 0x21};

  if(write(fd, command, sizeof(command)) == -1)
  {
    perror("error writing");
    return -1;
  }

  unsigned char response[2];
  if(read(fd,response,2) != 2)
  {
    printf("Error!\n");
    perror("error reading");
    return -1;
  }
  return response[0] + 128*response[1];
}

// Gets the position of a Maestro channel.
// See the "Serial Servo Commands" section of the user's guide.
int maestroGetPosition(int fd, unsigned char channel)
{
  printf("Reading currnet position...\n");
  // compact protocol
  unsigned char command[] = {GET_POSITION, channel};
  // Pololu protocol
  //unsigned char command[] = {0xAA, 0x0C, 0x10, channel};

  if(write(fd, command, sizeof(command)) == -1)
  {
    perror("error writing");
    return -1;
  }

  unsigned char response[2];
  if(read(fd,response,2) != 2)
  {
    printf("Error!\n");
    perror("error reading");
    return -1;
  }
  return response[0] + 256*response[1];
}

// Sets the target of a Maestro channel.
// See the "Serial Servo Commands" section of the user's guide.
// The units of 'target' are quarter-microseconds.
int maestroSetTarget(int fd, unsigned char channel, unsigned short target)
{

  // compact protocol
  unsigned char command[] = {SET_TARGET, channel, target & 0x7F, target >> 7 & 0x7F};
  // Pololu protocol
  //unsigned char command[] = {0xAA, 0x0C, 0x04, channel, target & 0x7F, target >> 7 & 0x7F};
  if (write(fd, command, sizeof(command)) == -1)
  {
    perror("error writing");
    return -1;
  }
  return 0;
}

int maestroGoHome(int fd)
{

  // compact protocol
  unsigned char command[] = {GO_HOME};
  // Pololu protocol
  //unsigned char command[] = {0xAA, 0x0C, 0x04, channel, target & 0x7F, target >> 7 & 0x7F};
  if (write(fd, command, sizeof(command)) == -1)
  {
    perror("error writing");
    return -1;
  }
  return 0;
}


int main()
{
  // Open the Maestro's virtual COM port.
  #ifdef _WIN32
    const char * device = "\\\\.\\USBSER000";  // Windows, "\\\\.\\COM6" also works
  #elif __APPLE__
    const char * device = "/dev/cu.usbmodem00034567";  // Mac OS X
  #else
    const char * device = "/dev/ttyACM0";  // Linux
  #endif



  int fd = open(device, O_RDWR | O_NOCTTY);
  if (fd == -1)
  {
    perror(device);
    return 1;
  }

#ifdef _WIN32
  _setmode(fd, _O_BINARY);
#else
  struct termios options;
  tcgetattr(fd, &options);
  options.c_iflag &= ~(INLCR | IGNCR | ICRNL | IXON | IXOFF);
  options.c_oflag &= ~(ONLCR | OCRNL);
  options.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
  tcsetattr(fd, TCSANOW, &options);
#endif

  int position = 0;
  int errors = 0;
  float fpoition = 0;

  errors = maestroGetErrors(fd);
  printf("Current errors are %x.\n", errors);

  for (int i = 0; i < 3; i++)
  {
    position = maestroGetPosition(fd, i);
    fpoition = (float)position/4;
    printf("Current position of ch %d is %f (%d).\n", i, fpoition, position);
  }

  maestroGoHome(fd);

  errors = maestroGetErrors(fd);
  printf("Current errors are %x.\n", errors);

  for (int i = 0; i < 3; i++)
  {
    position = maestroGetPosition(fd, i);
    fpoition = (float)position/4;
    printf("Current position of ch %d is %f (%d).\n", i, fpoition, position);
  }


/*
  int target = 0;
  printf("Setting target to %d (%d us).\n", target, target/4);
  maestroSetTarget(fd, 0, target);

  /*
  for (int i = 0; i < 10; i++)
  {
    position = maestroGetPosition(fd, 0);
    printf("Current position is %d.\n", position);

    //int target = (position < 6000) ? 7000 : 5000;

      int target = i;
      printf("Setting target to %d (%d us).\n", target, target/4);
      maestroSetTarget(fd, 0, target);
  }
  position = maestroGetPosition(fd, 0);
  printf("Current position is %d.\n", position);
  */

  close(fd);
  return 0;
}
