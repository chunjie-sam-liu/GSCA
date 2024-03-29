import { AfterViewInit, Component, OnInit, ViewChild } from '@angular/core';
import { environment } from 'src/environments/environment';
import immunecellstable from 'src/app/shared/constants/immunecells';
import immunecellsigtable from 'src/app/shared/constants/immunecellsig';
import cancerstat from 'src/app/shared/constants/cancerstatistical';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { ImmCellTableRecord } from 'src/app/shared/model/immcelltablerecord';
import { ImmCellSigTableRecord } from 'src/app/shared/model/immcellsigtablerecord';
import { CancerStatTableRecord } from 'src/app/shared/model/cancerstattablerecord';
import { MatTableDataSource } from '@angular/material/table';
import { MatAccordion } from '@angular/material/expansion';
import citations from 'src/app/shared/constants/citations';

@Component({
  selector: 'app-document',
  templateUrl: './document.component.html',
  styleUrls: ['./document.component.css'],
})
export class DocumentComponent implements OnInit, AfterViewInit {
  public assets = environment.assets;
  public citations = citations;

  // expanded
  panelOpenState = false;
  @ViewChild('accordion', { static: true }) Accordion: MatAccordion;
  accordionList: any;

  // immune cells
  public immunecells = new MatTableDataSource<ImmCellTableRecord>(immunecellstable);
  @ViewChild('paginatorImm') paginatorImm: MatPaginator;
  @ViewChild(MatSort) sortImm: MatSort;

  displayedColumnsImmuneCells = ['Immuneabbreviation', 'fullname'];
  displayedColumnsImmuneCellsHeader = ['Immune cell abbreviation', 'Immune cells fullname'];

  // immune cells signature
  public immunecellsignature = new MatTableDataSource<ImmCellSigTableRecord>(immunecellsigtable);
  @ViewChild('paginatorImmSig') paginatorImmSig: MatPaginator;
  @ViewChild(MatSort) sortImmSig: MatSort;

  displayedColumnsImmuneCellsSig = ['celltype', 'MarkerGeneSets'];
  displayedColumnsImmuneCellsHeaderSig = ['Immune cell abbreviation', 'Gene set signature of immune cell'];

  // cancer statistical
  public cancerstat = new MatTableDataSource<CancerStatTableRecord>(cancerstat);
  @ViewChild('paginatorCan') paginatorCan: MatPaginator;
  @ViewChild(MatSort) sortCan: MatSort;

  displayedColumnsCan = [
    'cancer_types',
    'expr',
    'immune',
    'cnv',
    'snv',
    'methy',
    'OS',
    'PFS',
    'DSS',
    'DFI',
    'pathologic_stage',
    'clinical_stage',
    'igcccg_stage',
    'masaoka_stage',
    'subtype',
  ];
  displayedColumnsCanHeader = [
    'Cancer types',
    'mRNA expression',
    'Immune',
    'CNV',
    'SNV',
    'Methylation',
    'Overall survival',
    'Progression free survival',
    'Disease specific survival',
    'Disease free survival',
    'Pathological stage',
    'Clinical stage',
    'IGCCCG stage',
    'MASAOKA stage',
    'Subtype',
  ];

  constructor() {}

  ngOnInit(): void {}

  ngAfterViewInit() {
    this.immunecells.paginator = this.paginatorImm;
    this.immunecells.sort = this.sortImm;
    this.immunecellsignature.paginator = this.paginatorImmSig;
    this.immunecellsignature.sort = this.sortImmSig;
    this.cancerstat.paginator = this.paginatorCan;
    this.cancerstat.sort = this.sortCan;
  }
  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.immunecells.filter = filterValue.trim().toLowerCase();

    this.cancerstat.filter = filterValue.trim().toLowerCase();

    if (this.immunecells.paginator) {
      this.immunecells.paginator.firstPage();
    }
    if (this.immunecellsignature.paginator) {
      this.immunecellsignature.paginator.firstPage();
    }
    if (this.cancerstat.paginator) {
      this.cancerstat.paginator.firstPage();
    }
  }
  public beforePanelClosed(panel) {
    panel.isExpanded = false;
    console.log('Panel going to close!');
  }
  public beforePanelOpened(panel) {
    panel.isExpanded = true;
    console.log('Panel going to  open!');
  }

  public afterPanelClosed($event: any) {
    console.log('Panel closed!');
  }
  public afterPanelOpened($event: any) {
    console.log('Panel opened!');
  }

  /*   public closeAllPanels() {
    this.Accordion.closeAll();
  }
  public openAllPanels() {
    this.Accordion.openAll();
  } */
}
