import { AfterViewInit, Component, OnInit, ViewChild } from '@angular/core';
import { environment } from 'src/environments/environment';
import immunecellstable from 'src/app/shared/constants/immunecells';
import cancerstat from 'src/app/shared/constants/cancerstatistical';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { ImmCellTableRecord } from 'src/app/shared/model/immcelltablerecord';
import { CancerStatTableRecord } from 'src/app/shared/model/cancerstattablerecord';
import { MatTableDataSource } from '@angular/material/table';
import { MatAccordion } from '@angular/material/expansion';

@Component({
  selector: 'app-document',
  templateUrl: './document.component.html',
  styleUrls: ['./document.component.css'],
})
export class DocumentComponent implements OnInit, AfterViewInit {
  public assets = environment.assets;

  // expanded
  panelOpenState = false;
  @ViewChild('accordion', { static: true }) Accordion: MatAccordion;
  accordionList: any;

  // immune cells
  public immunecells = new MatTableDataSource<ImmCellTableRecord>(immunecellstable);
  @ViewChild('paginatorImm') paginatorImm: MatPaginator;
  @ViewChild(MatSort) sortImm: MatSort;

  displayedColumnsImmuneCells = ['Immuneabbreviation', 'fullname'];
  displayedColumnsImmuneCellsHeader = ['Immune cells abbreviation', 'Immune cells fullname'];

  // cancer statistical
  public cancerstat = new MatTableDataSource<CancerStatTableRecord>(cancerstat);
  @ViewChild('paginatorCan') paginatorCan: MatPaginator;
  @ViewChild(MatSort) sortCan: MatSort;

  displayedColumnsCan = ['cancer_types', 'expr', 'survival', 'stage', 'immune', 'cnv', 'snv', 'methy'];
  displayedColumnsCanHeader = ['Cancer types', 'mRNA expression', 'Survival', 'Stage', 'Immune', 'CNV', 'SNV', 'Methylation'];

  constructor() {}

  ngOnInit(): void {}

  ngAfterViewInit() {
    this.immunecells.paginator = this.paginatorImm;
    this.immunecells.sort = this.sortImm;
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
