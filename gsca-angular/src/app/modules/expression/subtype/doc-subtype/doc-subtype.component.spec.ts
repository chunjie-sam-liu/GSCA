import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocSubtypeComponent } from './doc-subtype.component';

describe('DocSubtypeComponent', () => {
  let component: DocSubtypeComponent;
  let fixture: ComponentFixture<DocSubtypeComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocSubtypeComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocSubtypeComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
