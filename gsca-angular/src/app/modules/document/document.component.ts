import { AfterViewInit, Component, OnInit, ViewChild } from '@angular/core';
import { environment } from 'src/environments/environment';
import immunecellstable from 'src/app/shared/constants/immunecells';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { ImmCellTableRecord } from 'src/app/shared/model/immcelltablerecord';
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

  public immunecells = new MatTableDataSource<ImmCellTableRecord>(immunecellstable);
  @ViewChild('paginatorImm') paginatorImm: MatPaginator;
  @ViewChild(MatSort) sortImm: MatSort;
  public immtab = immunecellstable;

  displayedColumnsImmuneCells = ['Immuneabbreviation', 'fullname'];
  displayedColumnsImmuneCellsHeader = ['Immune cells abbreviation', 'Immune cells fullname'];
  constructor() {
    this.accordionList = [
      {
        id: 'panel-1',
        title: 'Expression module',
        description: '',
        isDisabled: false,
        isExpanded: false,
      },
      {
        id: 'panel-2',
        title: 'Immune module',
        description: '',
        isDisabled: true,
        isExpanded: false,
      },
      {
        id: 'panel-3',
        title: 'Mutation module',
        description: '',
        isDisabled: false,
        isExpanded: true,
      },
      {
        id: 'panel-4',
        title: 'Drug module',
        description: '',
        isDisabled: false,
        isExpanded: true,
      },
    ];
  }

  ngOnInit(): void {}

  ngAfterViewInit() {
    this.immunecells.paginator = this.paginatorImm;
    this.immunecells.sort = this.sortImm;
  }
  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.immunecells.filter = filterValue.trim().toLowerCase();

    if (this.immunecells.paginator) {
      this.immunecells.paginator.firstPage();
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
