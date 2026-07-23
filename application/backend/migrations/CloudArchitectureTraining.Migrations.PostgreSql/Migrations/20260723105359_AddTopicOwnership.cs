using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CloudArchitectureTraining.Migrations.PostgreSql.Migrations
{
    /// <inheritdoc />
    public partial class AddTopicOwnership : Migration
    {
        private static readonly string[] OwnerIndexColumns =
            ["OwnerProvider", "OwnerSubject"];

        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "OwnerProvider",
                table: "interview_topics",
                type: "character varying(40)",
                maxLength: 40,
                nullable: false,
                defaultValue: "Local");

            migrationBuilder.AddColumn<string>(
                name: "OwnerSubject",
                table: "interview_topics",
                type: "character varying(300)",
                maxLength: 300,
                nullable: false,
                defaultValue: "local-training-user");

            migrationBuilder.CreateIndex(
                name: "IX_interview_topics_OwnerProvider_OwnerSubject",
                table: "interview_topics",
                columns: OwnerIndexColumns);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_interview_topics_OwnerProvider_OwnerSubject",
                table: "interview_topics");

            migrationBuilder.DropColumn(
                name: "OwnerProvider",
                table: "interview_topics");

            migrationBuilder.DropColumn(
                name: "OwnerSubject",
                table: "interview_topics");
        }
    }
}
