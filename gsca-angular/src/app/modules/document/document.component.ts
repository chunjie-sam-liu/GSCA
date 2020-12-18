import { AfterViewInit, Component, OnInit, ViewChild } from '@angular/core';
import { environment } from 'src/environments/environment';
import immunecellstable from 'src/app/shared/constants/immunecells';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { ImmCellTableRecord } from 'src/app/shared/model/immcelltablerecord';
import { MatTableDataSource } from '@angular/material/table';
@Component({
  selector: 'app-document',
  templateUrl: './document.component.html',
  styleUrls: ['./document.component.css'],
})
export class DocumentComponent implements OnInit, AfterViewInit {
  public assets = environment.assets;
  public panelOpenState = false;

  public immunecells = new MatTableDataSource<ImmCellTableRecord>(immunecellstable);
  @ViewChild('paginatorImm') paginatorImm: MatPaginator;
  @ViewChild(MatSort) sortImm: MatSort;
  public immtab = immunecellstable;

  displayedColumnsImmuneCells = ['Immuneabbreviation', 'fullname'];
  displayedColumnsImmuneCellsHeader = ['Immune cells abbreviation', 'Immune cells fullname'];
  constructor() {}

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
}
