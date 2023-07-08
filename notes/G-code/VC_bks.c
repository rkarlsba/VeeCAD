//***********************************************************
//*
//*   Program:    VeeCad Breaks
//*   Created:    06/05/2016 2:32
//*   Author:
//*   Requested:
//*   Comments:   Reads a VeeCad breaks file and outputs D2nc Code to mill the breaks
//*
//************************************************************
//*
//* History:
//*
//* Read the .per file to get the size of the board
//* The format is read the file until a line with   "Width" : 25, or whatever is the width
//* then a similar line for the height
//*
//* The input .bks file format:
//* Line1:     X,   Y
//* Line2: blank
//* Line3:   5.5,   1
//* and so on until a blank line or more and then file end
//*
//* Instead of reading a .BKS file go down the .per file to a section "Breaks" and read the
//* breaks from there.
//************************************************************/


#include <stdio.h>
#include <stdlib.h>

#include <ctype.h>
#include <string.h>
#include "defs.h"

// Open files
#define debuga

// Get the Width and Height
#define debugb

//Process the breaks
#define debugc
#define debugc1
#define debugc2

// Compare strings
#define debugd

// Get a value
#define debuge

// Create the D2nc code
#define debugf

//
#define debugg


 void close_all( );                                        // Close all open files
 unsigned char open_files();                               // Open all files required
 int read_per_file();                                      // Read a line from the .per file

 unsigned char get_board_size(  );                         // Read the .per file to get the board size

 unsigned int compare( char key_wd0[] , char* recin  );    // Compare two character strings

 unsigned int get_breaks_section( );                       // Find the Breaks section in the .per file

 unsigned int process_breaks( );                           // Process the break lines and O/p to the .dcd file

 unsigned int d2nc( int x_dist, int x_half, int y_dist );  // Output the d2nc commands to file

 FILE *per, *D2ncCode, *param, *logfile;
 char *p_in;
 char per_name[13], D2nc_name[13];
 const char param_name[ ] = "param.txt";
 const char log_name[ ] = "LOG_FILE.txt";

 char key_wd0[6] = "Width";
 char key_wd1[7] = "Height";
 char key_wd2[7] = "Breaks";

 int board_width = 0;
 int board_height = 0;
 int last_x_pos = 0;
 int last_y_pos = 0;

 char recin[100];

 //****************************************************************************************************************************
//****************************************************************************************************************************
int main(int argc, char *argv[])
	{
	int  i = 0;
	int  c;
//	int  dummy1 =0;
//	int  dummy2 =0;
// 	int  ret;                                              /*  Value returned from sscanf */
//	char *retg;                                            /*  Value returned from fgets  */

	if ( open_files() != 1 )
	   {
	   return ( FALSE );
	   }

//	fputs("Opened the files now processing the .per file for the board size", logfile );
//	fputc( CR, logfile );

	if ( get_board_size( ) == FALSE )
	   {
#ifdef debugb
	   fputs("FALSE returned in get_board_size() section", logfile );
	   fputc( CR, logfile );
#endif
	   close_all();
	   return ( FALSE );
	   }
														   // board_width and board_height are Global int's
	fprintf( logfile, "Board Sizes : Width=%d,  Height=%d\n", board_width, board_height );
	// Board sizes are in Stripboard holes ie tenths of inches


	if ( get_breaks_section( ) == FALSE )
	   {
#ifdef debugb
	   fputs("FALSE returned in get_breaks_section()", logfile );
	   fputc( CR, logfile );
#endif
	   close_all();
	   return ( FALSE );
	   }

	   fputs("Now processing the .per file for the breaks", logfile );
	   fputc( CR, logfile );


	c = process_breaks();                                  // at the end of every break line it o/p's the D2nc code

	close_all();


	return 1;
	}

//****************************************************************************************************************************
unsigned int get_breaks_section( )
	{
	int i = 0;
	int  c;
	unsigned char found = 0;


		/*	Process the file  */
	#ifdef debugb
	fputs("Now looking in the .per file for the breaks", logfile );
	fputc( CR, logfile );
	#endif

	while ( c = read_per_file() != 0)
		{

		#ifdef debugb
		fprintf( logfile, "rec_length= %d  ", c );  // rec_count= %d   , rec_count
		fprintf( logfile, "->%s", recin  );
		#endif

		for (i = 0; i < c; i++)                            // Scan this line for
			{
			if ( recin[i] == '"' )
				{
				if ( recin[i+1] == 'B' )
					{
					 if ( compare( key_wd2, &recin[i+1] ) )
						 {
						 #ifdef debugb
	   		 			 fprintf( logfile, "Found Breaks Section\n" );
						 #endif
						 found = TRUE;
						 }
					}                                      // End if B
				}                                          // End if  "
			}                                              // End for
		if ( found == TRUE )
			{
			return ( TRUE );
			}
		}                                                  // End while
	#ifdef debugb
	fputs("End of file Breaks not found", logfile );
	fputc( CR, logfile );
	#endif
	return ( FALSE );                                      // End function get_breaks_section
	}                                                      // function end get_breaks_section( )

//***************************************************************************************************************************
unsigned int process_breaks()
	{
	int  i = 0;
	int  c = 0;
	int  x_dist = 0;
	int  y_dist = 0;
	unsigned char shift = 0;

	#ifdef debugc1
	fprintf( logfile, "rec_length= %d  rec_count= %d ->%s", c, rec_count, recin  );
	#endif


	while ( c = read_per_file() != 0)
		{
		x_dist = 0;
		y_dist = 0;
		shift = FALSE;
		i = 0;                                             // character position in the line

		#ifdef debugc1
		fprintf( logfile, "rec_length= %d  ", c );  // rec_count= %d   , rec_count
		fprintf( logfile, "->%s", recin  );
		#endif


		while ( i < c )
			{
			`statement`
			}


/*		for (i = 0; i < c; i++)                            // Scan this line for X & Y
			{
			if ( recin[i] != ' ' )
			   {
			   non_blank = TRUE;
			   }
			}
		if ( non_blank )
			{
			if ( recin[2] != ' ' )
				{
				x_dist = (recin[2] -48) * 10;
				#ifdef debugc
				fprintf( logfile, "X2X_dist=%c  \n", recin[2] );
				#endif
				x_dist = x_dist + (recin[3] - 48);
				#ifdef debugc
				fprintf( logfile, "X3X_dist=%c  \n", recin[3] );
				#endif
				}
			else
				{
				#ifdef debugc
				fprintf( logfile, "X_dist=%c  \n", recin[3] );
				#endif
				x_dist = recin[ 3 ] -48;
				}
			if ( recin[5] != ' ' )
				{
				x_half = recin[ 5 ] - 48;
				#ifdef debugc
				fprintf( logfile, "X_half=%c  \n", recin[5] );
				#endif
				}
										  // Now process the Y values
			if ( recin[9] != ' ' )
				{
				y_dist = (recin[9] -48) * 10;
				#ifdef debugc
				fprintf( logfile, "Y9Y_dist=%c  \n", recin[9] );
				#endif
				y_dist = y_dist + (recin[10] - 48);
				#ifdef debugc
				fprintf( logfile, "Y10Y_dist=%c  \n", recin[10] );
				#endif
				}
			else
				{
				#ifdef debugc
				fprintf( logfile, "Y_dist=%c  \n", recin[10] );
				#endif
				y_dist = recin[ 10 ] -48;
				}

			#ifdef debugc2
			fprintf( logfile, "Summary x_dist=%d  x_half=%d  y_dist=%d \n", x_dist, x_half, y_dist  );
			#endif
			d2nc( x_dist, x_half, y_dist);
			}
		else
			{
			fprintf( logfile, "blank line\n" );
			}
		}
 */                                                  // end while read the next line

	return ( 1 );
	}

//***************************************************************************************************************************
int get_val( char *chars1 )                                // Convert the size to int
	{
	int val = 0;
	int i = 0;

#ifdef debuge
	fprintf( logfile, "Begin get_val(), val = %d\n", val );
#endif

	val = atoi(chars1);

#ifdef debuge
	fprintf( logfile, "End   get_val(), val = %d\n", val );
#endif
	return ( val );
	}

//******************************************************************
unsigned int compare( char chars1[], char *chars2 )
	{
	int i = 0;
	int ch_size = 0;
	ch_size = strlen( chars1 );

	for ( i = 0; i <= ch_size-1; i++)
		{
#ifdef debugd
		fputc( chars1[i], logfile );
		fputc( chars2[i], logfile );
		fputc( CR, logfile );
#endif
		if ( chars1[i] != chars2[i] )
			{
#ifdef debugd
	fprintf( logfile, "In compare(F)  compare length = %d, 1st string=%s, 2nd string=%s\n", ch_size, chars1, chars2 );
#endif
			return ( FALSE );
			}
		}
#ifdef debugd
	fprintf( logfile, "In compare(T)  compare length = %d, 1st string=%s, 2nd string=%s\n", ch_size, chars1, chars2 );
#endif
	return ( TRUE );
	}

//****************************************************************************************************************************
unsigned char get_board_size(  )                                      //Read the per file to get the board dimensions
	{
	int i = 0;
//	char recin[100];
	int c;

		/*	Process the file  */
#ifdef debugb
	fputs("Now processing the .per file for the board size", logfile );
	fputc( CR, logfile );
#endif



	while ( read_per_file() != 0 )
		{

#ifdef debugb
		fprintf( logfile, "rec_length= %d  ", c );  // rec_count= %d   , rec_count
		fprintf( logfile, "->%s", recin  );
#endif

		for (i = 0; i < c; i++)                            // Scan this line for
			{
			if ( recin[i] == '"' )
				{
				switch ( recin[i+1] )
					{
					case 'W' :
						if ( compare( key_wd0, &recin[i+1] ) )
							{
							board_width = get_val( &recin[ i + 10 ] );
							}
#ifdef debugb
						fprintf( logfile, "Width= %d\n", board_width );
#endif
						break;

					case 'H' :
						if ( compare( key_wd1, &recin[i+1] ) )
							{
							board_height = get_val( &recin[ i + 11 ] );
							}
#ifdef debugb
						fprintf( logfile, "Height= %d\n", board_height );
#endif
						break;
					}                                      // End Switch
				}                                          // End if  "
			}                                              // End for
		if ( board_width > 0 && board_height > 0 )
			{
			return ( TRUE );
			}
		}                                                  // End while

	return ( FALSE );
	}                                                      // End function get_board_size

//****************************************************************************************************************************
unsigned int d2nc( x_dist, x_half, y_dist )
	{
	#ifdef debugf
//	fputs( "start to process D2nc output", logfile );
//	fputc( CR, logfile );
	fprintf( logfile, "x_dist = %d, x_half = %d, y_dist = %d\n", x_dist, x_half, y_dist );
	#endif
                                                      // ALL D2nc distances are calculated internally in hundreths of a mm
	int  i = 0;                                             // and then output in mm
	int  x_calc = 0;
	int  y_calc = 0;

	int  x_temp = 0;
	int  x_dec  = 0;

	int  y_temp = 0;
	int  y_dec  = 0;

	y_dist = board_height - y_dist;                        // Change coords from top of board to bottom

	x_calc = x_dist * 254;                                 // Convert distances (coords) to hundreths of a mm.
	if ( x_half != 0 )
		{
		x_calc += 127;
		}
	y_calc = y_dist *254;
	#ifdef debugf
	fprintf( logfile, "x_dist=%d, x_calc=%d   and  y_dist=%d, y_calc=%d \n", x_dist, x_calc, y_dist, y_calc );
	#endif

	x_temp = x_calc / 100;                                 // Prepare coords for output, all commands are absolute not relative
	x_dec  = x_calc % 100;
	y_temp = y_calc / 100;
	y_dec  = y_calc % 100;
 	#ifdef debugf
	fprintf( logfile, "x_temp=%d, x_dec=%d,  y_temp=%d, y_dec=%d \n", x_temp, x_dec, y_temp, y_dec );
	#endif

	fprintf( D2ncCode, "m%d.%d, %d.%d\n", x_temp, x_dec, y_temp, y_dec );
	#ifdef debugf
	fprintf( logfile,  "m%d.%d, %d.%d\n", x_temp, x_dec, y_temp, y_dec );
	#endif
	y_calc -= 254;
	y_temp = y_calc / 100;
	y_dec  = y_calc % 100;
	fprintf( D2ncCode, "e%d.%d, %d.%d\n", x_temp, x_dec, y_temp, y_dec );
	#ifdef debugf
	fprintf( logfile,  "e%d.%d, %d.%d\n", x_temp, x_dec, y_temp, y_dec );
	#endif

  	}                                                      // function end d2nc( x_dist, x_half, y_dist);

//****************************************************************************************************************************
 int read_per_file()                            // Read a line from the .per file
	{
	static int  rec_count = 0;
	int  c;
	if ( fgets( recin, 100, per ) != NULL )               // Read a line at a time until eof
		{
		c = strlen( recin );
		rec_count++;
		return ( c );
		}
	return ( 0 );
	}

//****************************************************************************************************************************
unsigned char open_files()
	{
	int i = 0;
	/*  Now Open the files
	 *  puts("Log file?	");
	 *  gets(log_name);
	*/
	char recin[100];
	logfile = fopen( log_name, "w" );                      // Open logfile to Write
	if( logfile == NULL )
		{
		puts( "Can't write log file" );                    // Message if can't open
		putchar( CR );
		return ( FALSE );
		}
	#ifdef debuga
	fputs( "Opened Logfile", logfile );
	fputc( CR, logfile );
	#endif

	param = fopen( param_name, "r" );                      // Open the parameter file to Read
	if( param == NULL )
		{
 		fputs( "Can't read paramfile", logfile );          // Message if can't open
		fputs( param_name, logfile );
		fputc( CR, logfile );
		close_all();
		return ( FALSE );
		}
	#ifdef debuga
	fputs( "Opened Parameter File", logfile );
	fputc( CR, logfile );
	#endif
											// Set up the file names to be opened
	p_in = fgets( recin, 100, param ); 		// Reads a line from the parameter file
	#ifdef debuga
	fputs( recin, logfile );
	fputc( CR, logfile );
	#endif
											// Set up the file names to be opened
	i = 0;
	while( recin[i] != '}' )                           //  Input file Project_Name.per}
		{
		per_name[i] = recin[i++];
		}
	per_name[i] = '\0';
	#ifdef debuga
	fputs( per_name, logfile );
	fputc( CR, logfile );
	#endif
/*
	p_in = fgets( recin, 100, param ); 		// Reads a line from the parameter file
	#ifdef debuga
	fputs( recin, logfile );
	fputc( CR, logfile );
	#endif
	i = 0;
	while( recin[i] != '}' )                           //  Input file of breaks}
		{
		bks_name[i] = recin[i++];
		}
	bks_name[i] = '\0';
	#ifdef debuga
	fputs( bks_name, logfile );
	fputc( CR, logfile );
	#endif
*/
	p_in = fgets( recin, 100, param ); 		// Reads a line from the parameter file
	#ifdef debuga
	fputs( recin, logfile );
	fputc( CR, logfile );
	#endif
	i = 0;
	while( recin[i] != '}' )                           //  Output file of D2nc code}
		{
		D2nc_name[i] = recin[i++];
		}
	D2nc_name[i] = '\0';
	#ifdef debuga
	fputs( D2nc_name, logfile );
	fputc( CR, logfile );
	#endif

						   // Now actually open the files
 						   //FILE *per, *bks, *D2ncCode
	per = fopen( per_name, "r" );                           //  Open per file
	if( per == NULL )
		{
		fputs( "Can't read ", logfile );
		fputs( per_name, logfile );
		fputc( CR, logfile );
		close_all();
		return ( FALSE );
		}
	#ifdef debuga
	fputs( "Opened ", logfile );
	fputs( per_name, logfile );
	fputc( CR, logfile );
	#endif
/*
	bks = fopen( bks_name, "r" );                       // Open bks file
 	if( bks_name == NULL )
		{
		fputs( "Can't write ", logfile );
		fputs( bks_name, logfile );
		fputc( CR, logfile );
		close_all();
		return ( FALSE );
		}
	#ifdef debuga
	fputs( "Opened ", logfile );
	fputs( bks_name, logfile );
	fputc( CR, logfile );
	#endif
*/
	D2ncCode = fopen( D2nc_name, "w" );                       // Open D2ncCode file
 	if( D2ncCode == NULL )
		{
		fputs( "Can't write ", logfile );
		fputs( D2nc_name, logfile );
		fputc( CR, logfile );
		close_all();
		return ( FALSE );
		}
	#ifdef debuga
	fputs( "Opened ", logfile );
	fputs( D2nc_name, logfile );
	fputc( CR, logfile );
	#endif
	return ( TRUE );
	}

 //****************************************************************************************************************************
void close_all( )
	 {
	// FILE *per, *D2ncCode, *param, *logfile;

	fclose( per );
	fclose( D2ncCode );
	fclose( logfile );
	fclose( param );
	}

