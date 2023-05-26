#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <stdbool.h>
#include <limits.h>

unsigned int xorshiftlocal32(unsigned int seed) {
    unsigned int x = seed;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    // seed = x;
    return x;
}

int rg2(){

	// Initialize the RandomSeeds struct with n random seeds
	unsigned int seed_list_copy[] = {2013404715, 1687426648, 1108673404, 294422395, 1753602871, 506471094, 1542693620, 1880046358, 1405904808, 283653032, 967244890, 471979078, 887962115, 428861283, 1265084686, 1649694236, 1554529398, 581730618, 162016123, 1917977045, 1935835769, 341606768, 21941108, 177693312, 748869462, 575257584, 110464482, 164411916, 696526162, 591460929, 995357840, 562447230, 131403929, 2104031244, 856869625, 1885006800, 463018691, 252079597, 1617569510, 1868923499, 535732630, 437330753, 193418929, 1423694745, 866192036, 1458503615, 925905333, 273237786, 2040234233, 1087921456, 43731183, 1828586354, 1429528224, 65672291, 2006279667, 30914038, 640929875, 2116744149, 195325954, 1337456038, 560721430, 1190683794, 1899903268, 692125360, 1147231391, 609289245, 429648512, 1610250082, 861368842, 2047218023, 1331689933, 1397101472, 337065128, 1525108862, 673312570, 1203257164, 836128829, 1599217903, 1476494950, 728879414, 539655712, 1520226133, 409982120, 1969183936, 1585898424, 268778139, 2000097975, 79344651, 238038640, 47940281, 1416800689, 798760071, 1238624076, 1169220309, 1490885431, 238371819, 1778509554, 1920533943, 1848621901, 492394749, 1820268318, 1032828186, 1889496221, 9849798, 410453400, 415325143, 1213106962, 1246582229, 2014543047, 542118264, 1975461643, 406715111, 2062344397, 237960115, 228415399, 1500759173, 506738255, 81029726, 1580103825, 744776895, 128970008, 849420866, 1543536966, 1367594084, 2018641176, 886938749, 1605965903, 1649667082, 659989045, 1307104156, 2142061831, 332773715, 192448694, 1884074405, 342623514, 602902094, 151915900, 1555730476, 1849484323, 18975299, 2097848741, 1677462318, 425690410, 2012709490, 1915422433, 654105810, 1365985016, 274677040, 735135536, 798605193, 1019453936, 864105544, 1648026059, 415507254, 84215980, 1519183587, 1302446004, 1690181883, 1021367022, 1962435049, 849802391, 1015945205, 147725116, 1042251085, 752535962, 490348630, 1645153179, 904451863, 2046079107, 1347153854, 923427162, 1996444200, 877132524, 1349117573, 1861670042, 645071310, 2003223383, 1080171410, 919748350, 590875271, 1878776603, 1939202286, 1454980816, 1379319015, 207225893, 1539196796, 751018954, 1509671897, 1081895032, 1772385976, 1324623298, 1931697423, 640847534, 1472348414, 826464861, 1393383496, 1962697045, 324134392, 150351711, 1861292504, 1671288247, 1073778874, 1710253056, 400937123, 275412799, 1424439450, 1046008433, 131152534, 357127213, 1965756784, 722027805, 88420168, 1757475422, 29524973, 1467739183, 1964701315, 1568721770, 71274490, 1326889564, 503133154, 1843660466, 504029214, 287346929, 337024352, 1976377629, 1113811790, 1730407849, 1791591026, 1437946183, 1880759560, 1505399882, 961750782, 807054786, 1068169290, 1362687905, 1082467585, 345125092, 261212691, 1213620119, 702252305, 79485827, 1935647925, 790672474, 1836961249, 1965172898, 110928009, 1654178917, 1386411020, 182202499, 833584833, 1889544174, 2025862966, 1337614048, 29407456, 215403670, 1166508029, 1143219246, 1945811519, 810615407, 433681781, 1679087432, 168531641, 1395432563, 338658570, 1236700931, 610636821, 1421126156, 1581826023, 871849512, 487262627, 136594681, 951335339, 275426904, 927267155, 640812940, 93116155, 1038195164, 147508209, 1479527175, 1220397664, 981093043, 1221587702, 1098776982, 171223443, 1250995158, 1314180652, 1337731472, 246730756, 1112508524, 863231, 680412538, 644112308, 169394872, 2075845101, 982770878, 1406095803, 538998274, 256413386, 840438178, 1410847786, 743676014, 977032859, 214699477, 1019102918, 1904300014, 855512418, 1112219073, 795011531, 1003020627, 444262601, 2015409195, 1984113670, 1665850303, 966702529, 7853465, 769361813, 133399533, 1345584937, 1016092569, 1245908057, 1346448168, 1696505107, 1890020365, 1515843040, 1624866561, 725307596, 774455195, 16381187, 981720982, 1614893374, 1427228974, 1725396996, 444442585, 1641928451, 597016267, 201258952, 349957221, 1709235340, 996270483, 1352977849, 6014293, 864196030, 1189607871, 1671864596, 1830898559, 1197461337, 293742761, 1964298092, 395562626, 1309835331, 1062722502, 1742010795, 858856790, 805259219, 1110370187, 336239703, 1530566815, 1884825383, 352620891, 364804150, 1352235109, 1779849865, 2090201146, 1796677694, 1274294668, 539733765, 1997936646, 1624251890, 101485458, 846723481, 829746091, 107499751, 1710919511, 2019353962, 1779364348, 1394334422, 1069331651, 2073107109, 1211148867, 1464894278, 1235458792, 126387721, 1059421425, 2094315583, 931646940, 22307964, 283071638, 314730108, 1907133347, 635692529, 679534258, 1111884808, 268058746, 622251756, 761078855, 1542353415, 1161985522, 611531853, 1019121657, 1263470980, 1458255335, 1848867748, 1370970731, 1021691198, 1720738062, 1002851431, 268541973, 642586066, 928474893, 1479690840, 2107480344, 16450037, 1606078561, 1019418121, 2110765620, 390241853, 1041726085, 246353611, 704971961, 801375785, 882046140, 1384506219, 1913260593, 1150104887, 2006757976, 526855800, 544974654, 1021259850, 1138387654, 1564096311, 137247182, 449159341, 1265480411
	};


	int distance = 17;
	double p = 0.001;
	int test_runs = 1;

	int seed_count = distance*distance + (distance+1)*(distance-1)/2;
	int data_qubit_start_address = seed_count*4 + 0x1800;
	printf("Dataqubits start address %x\n", data_qubit_start_address);
	int m_error_start_address = data_qubit_start_address + distance*distance*4;
	printf("Merror start address %x\n", m_error_start_address);
	int m_error_end_address = m_error_start_address + (distance+1)*(distance-1)/2*4;
	printf("Merror end address %x\n", m_error_end_address);

	bool data_errors[distance][distance];
	bool m_errors[2][distance+1][(distance-1)/2];

	int syndrome [distance+1][(distance-1)/2];

	int errors = 0;
	int syndrome_count = 0;

	unsigned int tmpVal;

	int gwx = distance + 1;
	int gwz = (distance - 1)/2;
	int bytes_per_round = gwx*gwz;
	bytes_per_round = (bytes_per_round + 7) >> 3;
	printf("bytes per round %d\n", bytes_per_round);

	int ns_e = (gwx - 1)*gwz;
	int ew_e = (gwx - 1)*gwz + 1;
	int ud_e = gwx*gwz;
	int corr_per_round = ns_e + ew_e + ud_e;
	int corr_bytes_per_round = (corr_per_round + 7)>>3;
	printf("corr bytes per round %d\n", corr_bytes_per_round);

	int num_messages = bytes_per_round*distance + 2;
	int num_returns = corr_bytes_per_round*distance + 3;

	int data_qubits = distance*distance;
    int m_error_per_round = (distance+1)*(distance-1)/2;

	unsigned int next_address = 0x0;
//	unsigned int latency_array[1000];
//	unsigned int iteration_array[100];
//  unsigned int latency_array_start_address = XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 0x1400;
//

	for (int t = 0; t < test_runs; t++) {
		next_address = 0x10;

		for (int k = 0; k < distance; k++) {
//			double* values = next_random_values(rs);
			int count = 0;
			for (int i = 0; i < distance; i++) {
				for (int j = 0; j < distance; j++) {
//					double value = next_random_value(count);
					seed_list_copy[count] = xorshiftlocal32(seed_list_copy[count]);
					double value = (double)seed_list_copy[count] / (double)UINT_MAX;
					// printf("%f\n", value);
					if (value < p) data_errors[i][j] = true;
					else data_errors[i][j] = false;
					count++;
					if(data_errors[i][j] != false) {
						printf("Data error at %d %d %d\n",k,i,j);
						errors++;
					}
				}
			}
			int saved_count = count;
			if(k==0){
				for (int i = 0; i < distance+1; i++) {
					for (int j = 0; j < (distance-1)/2; j++) {
						seed_list_copy[count] = xorshiftlocal32(seed_list_copy[count]);
						double value = (double)seed_list_copy[count] / (double)UINT_MAX;
						// printf("%f\n", value);
						if (value < p) m_errors[0][i][j] = true;
						else m_errors[0][i][j] = false;
						count++;
						if(m_errors[0][i][j] != false) {
							printf("M error at %d %d %d\n",k,i,j);
							errors++;
						}
					}
				}
			} else {
				for (int i = 0; i < distance+1; i++) {
					for (int j = 0; j < (distance-1)/2; j++) {
						m_errors[0][i][j] = m_errors[1][i][j];
					}
				}
			}
			count = saved_count;
			if(k < distance - 1) {
				for (int i = 0; i < distance+1; i++) {
					for (int j = 0; j < (distance-1)/2; j++) {
						seed_list_copy[count] = xorshiftlocal32(seed_list_copy[count]);
						double value = (double)seed_list_copy[count] / (double)UINT_MAX;
						// printf("%f\n", value);
						if (value < p) m_errors[1][i][j] = true;
						else m_errors[1][i][j] = false;
						count++;
						if(m_errors[1][i][j] != false) {
							printf("M error at %d %d %d\n",k,i,j);
							errors++;
						}
					}
				}
			} else {
				for (int i = 0; i < distance+1; i++) {
					for (int j = 0; j < (distance-1)/2; j++) {
						m_errors[1][i][j] = 0;
					}
				}
			}

			for (int i = 0; i < (distance + 1); i++) {
				for (int j = 0; j < (distance-1)/2; j++) {
					if(i==0){
						syndrome[i][j] = data_errors[i][j*2] ^ data_errors[i][j*2+1] ^ m_errors[0][i][j] ^ m_errors[1][i][j];
					}
					else if(i==distance) {
						syndrome[i][j] = data_errors[i-1][j*2+1] ^ data_errors[i-1][j*2+2] ^ m_errors[0][i][j] ^ m_errors[1][i][j];
					}
					else if(i%2 == 1) {
						syndrome[i][j] = data_errors[i-1][j*2+1] ^ data_errors[i-1][j*2+2] ^ data_errors[i][j*2+1] ^ data_errors[i][j*2+2] ^ m_errors[0][i][j] ^ m_errors[1][i][j];
					} else {
						syndrome[i][j] = data_errors[i-1][j*2] ^ data_errors[i-1][j*2+1] ^ data_errors[i][j*2] ^ data_errors[i][j*2+1] ^ m_errors[0][i][j] ^ m_errors[1][i][j];
					}
					if(syndrome[i][j] != 0) {
						syndrome_count++;
						printf("Syndrome at %d %d %d\n",k,i,j);
					}
				}
			}

			unsigned int val = 0;
			 unsigned int shift = 0;
			 for (int i = 0; i < distance+1; i++) {
				 for (int j = 0; j < (distance-1)/2; j++) {
					 val = val | (syndrome[i][j] << shift);
					 shift++;
					 if(shift == 8) {
						if(val>0) printf("address %x, %x\n", next_address, val);
						//  Xil_Out32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + next_address, val);
						 next_address = next_address + 0x4;
						 shift = 0;
						 val = 0;
					 }
				 }
			 }
			 if(shift != 0) {
				if(val>0)   printf("address %x, %x\n", next_address, val);
				//  Xil_Out32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + next_address, val);
				 next_address = next_address + 0x4;
			 }
		}

		
		 // */
		 printf("decoding part 2 started\n");
//		 xil_printf("decoding %d done %d \n",t,latency);
		 if(t%10000 == 0){
			 printf("decoding %d done %d \n",t,errors);
//			 printf("\r%d\%", (t/10000));
//			 fflush(stdout);
		 }
	}

	printf("Errors: %d\n", errors);
    printf("Error rate actual %f\n", (double)errors/(double)(test_runs*(data_qubits + m_error_per_round)*distance));
    printf("Syndrome count: %d\n", syndrome_count);
    printf("Syndrome rate actual %f\n", (double)syndrome_count/(double)(test_runs*(distance+1)*((distance-1)/2)*(distance)));



	return 0;
}


int main(){
	rg2();

    int distance = 17;
    int gwx = distance + 1;
	int gwz = (distance - 1)/2;
	int bytes_per_round = gwx*gwz;
	bytes_per_round = (bytes_per_round + 7) >> 3;
	printf("bytes per round %d\n", bytes_per_round);

	int ns_e = (gwx - 1)*gwz;
	int ew_e = (gwx - 1)*gwz + 1;
	int ud_e = gwx*gwz;
	int corr_per_round = ns_e + ew_e + ud_e;
	int corr_bytes_per_round = (corr_per_round + 7)>>3;
	printf("corr bytes per round %d\n", corr_bytes_per_round);

	int num_messages = bytes_per_round*distance + 2;
	int num_returns = corr_bytes_per_round*distance + 3;

    int return_start_address = num_messages*4 + 12;
	int return_end_address = return_start_address + num_returns*4;

    printf("%x %x %x %x",num_messages, num_returns, return_start_address, return_end_address);
    return 0;

}