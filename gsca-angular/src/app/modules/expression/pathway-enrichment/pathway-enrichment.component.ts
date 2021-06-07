import { AfterViewInit, Component, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { ExpressionApiService } from '../expression-api.service';
import collectionList from 'src/app/shared/constants/collectionlist';
import { MatTableDataSource } from '@angular/material/table';
import { PaenTableRecord } from 'src/app/shared/model/Paentablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { animate, state, style, transition, trigger } from '@angular/animations';
import * as XLSX from 'xlsx';

@Component({
  selector: 'app-pathway-enrichment',
  templateUrl: './pathway-enrichment.component.html',
  styleUrls: ['./pathway-enrichment.component.css'],
})
export class PathwayEnrichmentComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  dataSourcePaenLoading = true;
  dataSourcePaen: MatTableDataSource<PaenTableRecord>;
  showPaenTable = true;
  @ViewChild('paginatorPaen') paginatorPaen: MatPaginator;
  @ViewChild(MatSort) sortPaen: MatSort;
  displayedColumnsPaen = ['Method', 'ID', 'Description', 'GeneRatio', 'pvalue', 'fdr', 'qvalue', 'Hits'];
  displayedColumnsPaenHeader = [
    'Method',
    'Pathway ID',
    'Description',
    'Hits/Input',
    // 'n of term/background',
    'P value',
    'FDR',
    'Q value',
    'Hits',
  ];
  expandedElement: PaenTableRecord;
  expandedColumn: string;

  PaenImage: any;
  PaenPdfURL: string;
  PaenImageLoading = true;
  showPaenImage = true;

  // single gene
  PaenResourceUUID: string;
  PaenSingleCancerTypeImage: any;
  PaenSingleCancerTypePdfURL: string;
  PaenSingleCancerTypeImageLoading = true;
  showPaenSingleCancerTypeImage = false;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.dataSourcePaenLoading = true;
    this.PaenImageLoading = true;
    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourcePaenLoading = false;
      this.PaenImageLoading = false;
      this.showPaenTable = false;
      this.showPaenImage = false;
    } else {
      this.expressionApiService.getPaenAnalysis(postTerm).subscribe(
        (res) => {
          this.PaenResourceUUID = res.uuidname;

          this.showPaenTable = true;
          this.expressionApiService.getPaenTable('preanalysised_enrichment', res.uuidname).subscribe(
            (r) => {
              this.dataSourcePaenLoading = false;
              this.dataSourcePaen = new MatTableDataSource(r);
              this.dataSourcePaen.paginator = this.paginatorPaen;
              this.dataSourcePaen.sort = this.sortPaen;
            },
            (e) => {
              this.showPaenTable = false;
              this.dataSourcePaenLoading = false;
            }
          );

          this.expressionApiService.getExprPaenPlot(res.uuidname).subscribe(
            (exprPaenuuids) => {
              this.PaenPdfURL = this.expressionApiService.getResourcePlotURL(exprPaenuuids.paenplotuuid, 'pdf');
              this.expressionApiService.getResourcePlotBlob(exprPaenuuids.paenplotuuid, 'png').subscribe(
                (r) => {
                  this.showPaenImage = true;
                  this.PaenImageLoading = false;
                  this._createImageFromBlob(r, 'PaenImage');
                },
                (e) => {
                  this.showPaenImage = false;
                }
              );
            },
            (e) => {
              this.PaenImageLoading = false;
              this.showPaenImage = false;
            }
          );
        },
        (err) => {
          this.showPaenTable = false;
          this.showPaenImage = false;
        }
      );
    }
  }

  ngAfterViewInit(): void {}

  private _validCollection(st: ExprSearch): any {
    st.validColl = st.cancerTypeSelected
      .map((val) => {
        return collectionList.deg.collnames[collectionList.deg.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }

  private _createImageFromBlob(res: Blob, present: string) {
    const reader = new FileReader();
    reader.addEventListener(
      'load',
      () => {
        switch (present) {
          case 'PaenImage':
            this.PaenImage = reader.result;
            break;
          case 'PaenSingleCancerTypeImage':
            this.PaenSingleCancerTypeImage = reader.result;
            break;
        }
      },
      false
    );
    if (res) {
      reader.readAsDataURL(res);
    }
  }

  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourcePaen.filter = filterValue.trim().toLowerCase();

    if (this.dataSourcePaen.paginator) {
      this.dataSourcePaen.paginator.firstPage();
    }
  }
  /* public expandDetail(element: PaenTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.PaenSinglePathTypeImageLoading = true;
      this.showPaenSinglePathTypeImage = false;
      if (this.expandedColumn === 'cancertype') {
        this.expressionApiService.getPaenSinglePathTypePlot(this.PaenResourceUUID, this.expandedElement.cancertype).subscribe(
          (res) => {
            this.PaenSingleCancerTypePdfURL = this.expressionApiService.getResourcePlotURL(res.Paenplotsinglepathtypeuuid, 'pdf');
            this.expressionApiService.getResourcePlotBlob(res.Paenplotsinglecancertypeuuid, 'png').subscribe(
              (r) => {
                this.PaenSingleCancerTypeImageLoading = false;
                this.showPaenSingleCancerTypeImage = true;
                this._createImageFromBlob(r, 'PaenSingleCancerTypeImage');
              },
              (e) => {
                this.PaenSingleCancerTypeImageLoading = false;
                this.showPaenSingleCancerTypeImage = false;
              }
            );
          },
          (err) => {
            this.PaenSingleCancerTypeImageLoading = false;
            this.showPaenSingleCancerTypeImage = false;
          }
        );
      }
    } else {
      this.PaenSingleCancerTypeImageLoading = false;
      this.showPaenSingleCancerTypeImage = false;
    }
  } */
  /*   public triggerDetail(element: PaenTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  } */
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.dataSourcePaen.data, { header: this.displayedColumnsPaen });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'PaenTable.xlsx');
  }
}
